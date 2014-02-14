package pf::CHI;

=head1 NAME

pf::CHI add documentation

=cut

=head1 DESCRIPTION

pf::CHI

=cut

use strict;
use warnings;
use base qw(CHI);
use CHI::Driver::Memcached;
use CHI::Driver::RawMemory;
#use pf::CHI::Driver::Role::Memcached::Clear;
use pf::file_paths;
use pf::IniFiles;
use Hash::Merge;
use List::MoreUtils qw(uniq);

Hash::Merge::specify_behavior(
    {
    'SCALAR' => {
        'SCALAR' => sub {$_[1]},
        'ARRAY'  => sub {[$_[0], @{$_[1]}]},
        'HASH'   => sub {$_[1]},
      },
      'ARRAY' => {
        'SCALAR' => sub {$_[1]},
        'ARRAY'  => sub {[uniq @{$_[0]}, @{$_[1]}]},
        'HASH'   => sub {$_[1]},
      },
      'HASH' => {
        'SCALAR' => sub {$_[1]},
        'ARRAY'  => sub {[values %{$_[0]}, @{$_[1]}]},
        'HASH' => sub {
            Hash::Merge::_merge_hashes($_[0], $_[1]);
        },
      },
    },
    'PF_CHI_MERGE'
);

our $chi_config = pf::IniFiles->new( -file => $chi_config_file, -allowempty => 1) or die;
our %DEFAULT_CONFIG = (
    'namespace' => {
        'configfilesdata' => {'storage' => 'configfilesdata'},
        'configfiles'     => {'storage' => 'configfiles'}
    },
    'memoize_cache_objects' => 1,
    'defaults'              => {'serializer' => 'Storable'},
    'storage'               => {
        'raw' => {
            'global' => '1',
            'driver' => 'RawMemory'
        }
    }
);

sub chiConfigFromIniFile {
    my @keys = uniq map { s/ .*$//; $_; } $chi_config->Sections;
    my %args;
    foreach my $key (@keys) {
        $args{$key} = sectionData($chi_config,$key);
    }
    foreach my $storage (values %{$args{storage}}) {
        setFileDriverParams($storage) if($storage->{driver} eq 'File');
        foreach my $param (qw(servers traits roles)) {
            if(exists $storage->{$param}) {
                my $value =  listify($storage->{$param});
                $storage->{$param} = [ map { split /\s*,\s*/, $_ } @$value ];
            }
        }
        if ( exists $storage->{traits} ) {
            $storage->{param_name} = $storage->{traits};
        }
    }
    setRawL1CacheAsLast($args{storage}{configfiles});
    my $merge = Hash::Merge->new('PF_CHI_MERGE');
    return $merge->merge( \%DEFAULT_CONFIG, \%args );
}

sub setFileDriverParams {
    my ($storage) = @_;
    $storage->{dir_create_mode} = oct('02775');
    $storage->{file_create_mode} = oct('00664');
    $storage->{umask_on_store} = oct('00007');
    $storage->{traits} = ['+pf::Role::CHI::Driver::FileUmask'];
}

sub setRawL1CacheAsLast {
    my ($storage) = @_;
    if ( exists $storage->{l1_cache} ) {
        setRawL1CacheAsLast($storage->{l1_cache});
    } else {
        $storage->{l1_cache} = { 'storage' => 'raw' };
    }
}

sub sectionData {
    my ($config,$section) = @_;
    my %args;
    foreach my $param ($config->Parameters($section)) {
        $args{$param} = $config->val($section,$param);
    }
    my @sections = uniq map { s/^$section ([^ ]+).*$//;$1 } grep { /^$section / } $config->Sections;
    foreach my $name (@sections) {
        $args{$name} = sectionData($config,"$section $name");
    }
    return \%args;
}

__PACKAGE__->config(chiConfigFromIniFile());

=head2 listify

Will change a scalar to an array ref if it is not one already

=cut

sub listify($) {
    ref($_[0]) eq 'ARRAY' ? $_[0] : [$_[0]]
}


=head1 AUTHOR

Inverse inc. <info@inverse.ca>


=head1 COPYRIGHT

Copyright (C) 2005-2013 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and::or
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
