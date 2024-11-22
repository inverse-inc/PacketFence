package pf::UnifiedApi::Controller::Config::ConnectionProfiles;

=head1 NAME

pf::UnifiedApi::Controller::Config::ConnectionProfiles -

=cut

=head1 DESCRIPTION

pf::UnifiedApi::Controller::Config::ConnectionProfiles

=cut

use strict;
use warnings;
use captiveportal::DynamicRouting::Application;
use Mojo::Asset;
use Mojo::Base qw(pf::UnifiedApi::Controller::Config);
use pf::ConfigStore::Profile;
use pf::UnifiedApi::Request;
use pfappserver::Form::Config::Profile;
use pfappserver::Form::Config::Profile::Default;
use File::Slurp qw(read_file write_file);
use POSIX qw(:errno_h);
use JSON::MaybeXS qw();
use File::Find;
use File::stat;
use pf::cluster;
use File::Spec::Functions qw(catfile splitpath);
use pf::config qw(%Config);
use pf::util;
use pf::log;
use List::Util qw(any first none);
use pf::file_paths qw(
    $captiveportal_profile_templates_path
    $captiveportal_default_profile_templates_path
    $captiveportal_templates_path
);
use pf::error qw(is_error);
use pfconfig::git_storage;
use MIME::Base64 qw(encode_base64 decode_base64);

has 'config_store_class' => 'pf::ConfigStore::Profile';
has 'form_class' => 'pfappserver::Form::Config::Profile';
has 'primary_key' => 'connection_profile_id';

my %NUMERICAL_SORTS = (
    mtime => undef,
    size => undef,
);

my %ALLOWED_SORTS = (
    map { $_ => undef } qw(mtime size type name)
);

sub form {
    my ($self, $item) = @_;
    if ( ($item->{id} // '') eq 'default') {
        return 200, pfappserver::Form::Config::Profile::Default->new;
    }

    return $self->SUPER::form($item);
}

=head2 files

files

=cut

sub files {
    my ($self) = @_;
    my ($status, $file_listing_info_or_error) = $self->file_listing_info();
    if (is_error($status)) {
        return $self->render_error($status, $file_listing_info_or_error);
    }

    ($status, my $cmps_or_error) = $self->build_compare_functions($file_listing_info_or_error);
    if (is_error($status)) {
        return $self->render_error($status, $cmps_or_error);
    }

    return $self->render(
        json => profileFileListing($self->id, $cmps_or_error)
    );
}

=head2 build_compare_functions

build_compare_functions

=cut

sub build_compare_functions {
    my ($self, $file_listing_info) = @_;
    my $sort = $file_listing_info->{sort};
    my @invalid_sort_specs;
    for my $sort_spec (@$sort) {
        my $s = $sort_spec;
        $s =~ s/  *(DESC|ASC)$//i;
        if (!exists $ALLOWED_SORTS{$s}) {
            push @invalid_sort_specs, $sort_spec;
        }
    }

    if (@invalid_sort_specs) {
        return 422, "Invalid sort spec given '" . join(", ", @invalid_sort_specs) . "'";
    }

    return 200, make_compare_functions($sort);
}

=head2 file_listing_info

file_listing_info

=cut

sub file_listing_info {
    my ($self) = @_;
    my $params = $self->req->query_params->to_hash;
    $params->{sort} = [expand_csv($params->{sort} // "type,name")];
    return 200, $params;
}

=head2 get_file

get_file

=cut

sub get_file {
    my ($self) = @_;
    my $file = $self->stash->{file_name};
    if (!valid_file_path($file)) {
       return $self->render_error(412, "invalid characters in file '$file'");
    }

    my $id = $self->id;
    my $path = findPath($id, $file);
    if (!defined $path) {
        return $self->render_error(404, "'$file' not found");
    }

    my $content = read_file($path);
    my $encoded = encode_base64($content);

    my $asset = Mojo::Asset::Memory->new;
    $asset->add_chunk($encoded);

    return $self->reply->asset($asset);
}

=head2 new_file

new_file

=cut

sub new_file {
    my ($self) = @_;
    my $file = $self->stash->{file_name};
    if (!valid_file_path($file)) {
       return $self->render_error(412, "invalid characters in file '$file'");
    }

    my $path = profileFilePath($self->id, $file);
    if (-e $path) {
       return $self->render_error(412, "'$file' already exists");
    }

    my $content = decode_base64($self->req->body);
    eval {
        my (undef, $file_parent_dir, undef) = splitpath($path);
        pf_make_dir($file_parent_dir);
        write_file($path, {binmode => ':raw', no_clobber => 1}, $content);
    };
    if ($@) {
       pf::log::get_logger->error("Error writing file: $@");
       return $self->render_error(422, "Error writing to the '$file'");
    }

    if (my $err = $self->_sync_files($path)) {
        return $self->render(status => $err->{status}, json => $err);
    }

    return $self->render(json => {message => "'$file' created"});
}

=head2 replace_file

replace_file

=cut

sub replace_file {
    my ($self) = @_;
    my $file = $self->stash->{file_name};
    if (!valid_file_path($file)) {
       return $self->render_error(412, "invalid characters in file '$file'");
    }
    my $id = $self->id;

    if (!defined findPath($id, $file)) {
        return $self->render_error(404, "'$file' not found");
    }

    my $path = profileFilePath($id, $file);
    my $content = decode_base64($self->req->body);

    eval {
        my (undef, $file_parent_dir, undef) = splitpath($path);
        pf_make_dir($file_parent_dir);
        write_file($path, {atomic=> 1, binmode => ':raw', no_clobber => 1}, $content);
    };
    if ($@) {
       pf::log::get_logger->error("Error writing file: $@");
       return $self->render_error(422, "Error writing to the '$file'");
    }

    if (my $err = $self->_sync_files($path)) {
        return $self->render(status => $err->{status}, json => $err);
    }

    return $self->render(json => {message => "'$file' replaced"});
}


=head2 valid_file_path

valid_file_path

=cut

sub valid_file_path {
    my ($path) = @_;
    return $path !~ /(\/)?\.\.\//;
}


=head2 delete_path

delete_path

=cut

sub delete_file {
    my ($self) = @_;
    my $file = $self->stash->{file_name};
    if (!valid_file_path($file)) {
        return $self->render_error( 412, "invalid characters in file '$file'" );
    }

    my $path = profileFilePath($self->id, $file);
    if (-d $path) {
        if (!rmdir($path)) {
            $self->log->error("'$file': Error $!");
            return $self->render_error(422, "Error deleting '$file'");
        }
    } elsif (!unlink($path)) {
        if ($! == ENOENT()) {
            return $self->render_error(404, "'$file' not found");
        }

        $self->log->error("'$file': Error $!");
        return $self->render_error(422, "Error deleting '$file'");
    }

    if (my $err = $self->_sync_delete_files($path)) {
        return $self->render(json => $err, status => $err->{status});
    }

    return $self->render(json => { message => "'$file' deleted" });
}

=head2 profileFilePath

profileFilePath

=cut

sub profileFilePath {
    my ($profile, $file) = @_;
    my $path = catfile($captiveportal_profile_templates_path, $profile, $file);
    return $path;
}

sub findPath {
    my ($profile, $file) = @_;
    return first { -f $_ } map { catfile($_, $file) } pathLookup($profile);
}

=head2 make_compare_functions

make_compare_functions

=cut

sub make_compare_functions {
    my ($sort_names) = @_;
    [map { make_compare_function($_) } @$sort_names];
}

=head2 make_compare_function

make_compare_function

=cut

sub make_compare_function {
    my ($order_by) = @_;
    my $direction = 'asc';
    if ($order_by =~ /^([^ ]+) (DESC|ASC)$/i ) {
       $order_by = $1;
       $direction = lc($2);
    }

    if ($direction eq 'desc') {
        return exists $NUMERICAL_SORTS{$order_by}
          ? make_num_rcmp($order_by)
          : make_string_rcmp($order_by);
    }

    return exists $NUMERICAL_SORTS{$order_by}
      ? make_num_cmp($order_by)
      : make_string_cmp($order_by);
}

=head2 profileFileListing

profileFileListing

=cut
sub profileFileListing {
    my ($id, $cmps) = @_;
    my $entries = mergePaths(pathLookup($id));
    sortEntry($entries, $cmps // [] );
    return $entries;
}

=head2 pathLookup

parent paths

=cut

sub pathLookup {
    my ($profile) = @_;
    my @dirs = (catfile($captiveportal_profile_templates_path, $profile));
    if ($profile eq 'default') {
        push @dirs, $captiveportal_templates_path;
    } else {
        push @dirs, $captiveportal_default_profile_templates_path, $captiveportal_templates_path;
    }

    return @dirs;
}

=head2 standardPlaceholder

standardPlaceholder

=cut

sub standardPlaceholder {
    my ($self) = @_;
    my $value = $self->SUPER::standardPlaceholder();
    $value->{description} = '';
    return $value;
}

=head2 mergePaths

mergePaths

=cut

sub mergePaths {
    my ($templateDir, @parentDirs) = @_;
    my %paths;
    my $root;
    find(
        {
            wanted => sub {
                my $full_path = my $path = $_;
                #Just get the file path minus the parent directory
                $path =~ s/^\Q$File::Find::topdir\E\/?//;
                return if exists $paths{$path};
                my $dir = $File::Find::dir;
                #Just get the directory path minus the parent directory
                $dir =~ s/^\Q$File::Find::topdir\E\/?//;
                my $data;
                if ( -d $full_path ) {
                    if (dir_excluded($path)) {
                       $File::Find::prune = 1;
                       return;
                    }

                    $data = { name => file_name($path), type => 'dir', size => 0, mtime => 0, entries => [] };
                }
                else {
                    return if file_excluded($path);
                    $data = makeFileInfo( $path, $full_path, $templateDir, @parentDirs );
                }

                $paths{$path} = $data;
                if ( $path ne '' ) {
                    push @{ $paths{$dir}{entries} }, $data;
                }
            },
            no_chdir => 1
        },
        grep { -e $_ } ( $templateDir, @parentDirs)
    );

    $root = $paths{''};;
    return $root;
}

sub file_name {
    my ($path) = @_;
    my (undef, undef, $file) = splitpath($path);
    return $file;
}

=head2 file_excluded

file_excluded

=cut

sub file_excluded {
    my ($file) = @_;
    return $file !~ /\.(html|mjml|jpg|jpeg|gif|png|svg|json|js|css|scss|otf|ttf|woff|woff2)$/ || $file =~ /^\./;
}

sub dir_excluded {
    my ($dir) = @_;
    return $dir =~ /\/node_modules/ || $dir =~ /^\./;
}

sub makeFileInfo {
    my ($short_path, $full_path, $templateDir, @parentPaths) = @_;
    my $stat = stat($full_path);
    return {
        type  => 'file',
        name  => file_name($short_path),
        size  => $stat->size,
        mtime => $stat->mtime,
        not_deletable => notDeletable($short_path, $full_path, $templateDir, @parentPaths),
        not_revertible => notRevertible($short_path, $full_path, $templateDir, @parentPaths),
    };
}

=head2 isFileRevertible

isFileRevertible

=cut

sub isFileRevertible {
    my ($short_path, @parentPaths) = @_;
    return any { -f catfile( $_, $short_path ) } @parentPaths;
}

=head2 _sync_files

sync_files

=cut

sub _sync_files {
    my ($self, @files) = @_;
    if (@files == 0) {
        return undef;
    }

    if($cluster_enabled) {
        my $failed = pf::cluster::sync_files(\@files);
        if (@$failed){
            return { message => "Failed to sync file on " . join(', ', @$failed) , status => 500};
        }
    }

    if(pfconfig::git_storage->is_enabled) {
        for my $file (@files) {
            my ($res, $msg) = pfconfig::git_storage->commit_file($file, strip_path_for_git_storage($file), push => 0);
            if(!$res) {
                return { message => $msg, status => 500 };
            }
        }
        my ($res, $msg) = pfconfig::git_storage->push();
        if(!$res) {
            return { message => $msg, status => 500 };
        }
    }

    return undef;
}

=head2 _sync_delete_files

_sync_delete_files

=cut

sub _sync_delete_files {
    my ($self, @files) = @_;
    if (@files == 0) {
        return undef;
    }

    if($cluster_enabled) {
        my $failed = pf::cluster::sync_file_deletes(\@files);
        if (@$failed) {
            my $id = $self->id;
            return { message => "Failed to revert profile $id on " . join(', ', @$failed) , status => 500 };
        }
    }

    if(pfconfig::git_storage->is_enabled) {
        for my $file (@files) {
            my ($res, $msg) = pfconfig::git_storage->delete_file(strip_path_for_git_storage($file), push => 0);
            if(!$res) {
                return { message => $msg, status => 500 };
            }
        }
        my ($res, $msg) = pfconfig::git_storage->push();
        if(!$res) {
            return { message => $msg, status => 500 };
        }
    }

    return undef;
}

=head2 notDeletable

notDeletable

=cut

sub notDeletable {
    my ($short_path, $full_path, $templateDir, @parentPaths) = @_;
    return ( $full_path eq catfile( $templateDir, $short_path )
          && ( none { -f catfile( $_, $short_path ) } @parentPaths ) )
      ? json_false()
      : json_true();
}

sub notRevertible {
    my ($short_path, $full_path, $templateDir, @parentPaths) = @_;
    return ( $full_path eq catfile( $templateDir, $short_path )
          && isFileRevertible($short_path, @parentPaths) )
      ? json_false()
      : json_true();
}

=head2 sortEntry

Sorts the dir entries by name

=cut

sub sortEntry {
    my ($root, $cmps) = @_;
    if ($root->{type} eq 'dir' && exists $root->{entries}) {
        my $entries = $root->{entries};
        foreach my $entry (@$entries) {
            if ($entry->{type} eq 'dir') {
                sortEntry($entry, $cmps);
            }
        }

        @$entries = sort { mcmp ($a, $b, $cmps) } @$entries;
    }
}

sub json_true {
    return do { bless \(my $a = 1), "JSON::PP::Boolean" };
}

sub json_false {
    return do { bless \(my $a = 0), "JSON::PP::Boolean" };
}

sub cached_form_key {
    my ($self, $item, @args) = @_;
    my $id = $item->{id} // '';
    return $id eq 'default' ? 'cached_form_default' : 'cached_form'
}

=head2 create_response

create_response

=cut

sub create_response {
    my ($self, $id, @args) = @_;
    my $resp = $self->SUPER::create_response($id, @args);
    my $path = profileFilePath($self->id, '');
    if (-e -d $path) {
        my $count = do {
            opendir(my $dh, $path);
            my $c =()= readdir($dh);
            closedir($dh);
            $c -= 2
        };
        if ($count) {
            $resp->{warnings} = [
                { message => "There are $count files in profile template please review", id => $id},
            ];
        }
    }

    return $resp;
}

sub preview_file {
    my ($self) = @_;
    my $file = $self->stash->{file_name};
    if (!valid_file_path($file)) {
       return $self->render_error(412, "invalid characters in file '$file'");
    }

    my $id = $self->id;
    my $path = findPath($id, $file);
    if (!defined $path) {
        return $self->render_error(404, "'$file' not found");
    }

    if ($path !~ /\.html$/) {
        my $type = $self->app->types->file_type($path);
        if ($type) {
            $self->res->headers->content_type($type);
        }
        $self->reply->file($path);
        return;
    }

    my $profile =
      pf::Connection::ProfileFactory->instantiate( "00:11:22:33:44:55",
        { portal => $self->id } );

    my $application = captiveportal::DynamicRouting::Application->new(
        user_session => {},
        session => {client_mac => '00:11:22:33:44:55', client_ip => '1.2.3.4'},
        profile => $profile,
        request => bless($self->req, 'pf::UnifiedApi::Request'),
        root_module_id => $profile->getRootModuleId(),
    );

    $application->render($file, $self->fake_profile_data);
    $self->render(text => $application->template_output);
}

sub fake_profile_data {
    return {
        logo             => $Config{'general'}{'logo'},
        timer            => $Config{'captive_portal'}{'network_redirect_delay'},
        client_mac       => '00:11:22:33:44:55',
        client_ip        => '1.2.3.4',
        username         => 'mcrispin',
        last_port        => '4097',
        last_vlan        => '102',
        last_ssid        => 'PacketFence-Secure',
        last_switch      => '10.0.0.4',
        message          => 'Test message',
        dhcp_fingerprint => '1,28,2,3,15,6,119,12,44,47,26,121,42',
        last_connection_type => 'Wireless-802.11-EAP',
        nodes                => [
            {
                status       => 'reg',
                mac          => '00:11:22:33:44:55',
                device_class => 'Ubuntu',
                regdate      => '2016-01-02 03:04:05'
            },
            {
                status       => 'reg',
                mac          => '11:22:33:44:55:66',
                device_class => 'Android',
                regdate      => '2016-02-03 04:05:06'
            }
        ]
    };
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2024 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

1;
