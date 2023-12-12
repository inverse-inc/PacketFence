#!/usr/bin/perl

=head1 NAME

addons/upgrade/to-10.1-move-radius-configuration-parameter.pl

=cut

=head1 DESCRIPTION

Move radius configuration parameters to associated new files

=cut

use strict;
use warnings;
use lib qw(/usr/local/pf/lib /usr/local/pf/lib_perl/lib/perl5);
use pf::IniFiles;
use pf::file_paths qw($authentication_config_file $domain_config_file);
use pf::util;
use Digest::MD4;
use Encode;
use MIME::Base64;

my $ini = pf::IniFiles->new(-file => $domain_config_file, -allowempty => 1);

unless ($ini) {
    exit;
}

my $updated = 0;
for my $section (grep {/^\S+$/} $ini->Sections()) {

    if (($ini->exists($section, 'machine_account')) || ($ini->exists($section, 'machine_account_password'))) {
        print("Section: ", $section, " already has machine_account and machine_account_password set. skipped\n");
        next;
    }

    my $samba_conf_path = "/chroots/$section/etc/samba/$section.conf";
    my $samba_ini = pf::IniFiles->new(-file => $samba_conf_path, -allowempty => 1);
    unless ($samba_ini) {
        print("unable to find correspond samba conf file in $samba_conf_path, terminated\n");
        exit;
    }

    my $dns_name = $ini->val($section, "dns_name");
    my $work_group = $samba_ini->val("global", "workgroup");
    my $realm = $samba_ini->val("global", "realm");


    # the tdb file should be located at /var/lib/samba/secrets.tdb, but here we use cache instead
    my $secret_tdb_file = "/chroots/$section/var/cache/samba/secrets.tdb";

    my $exit_code = 0;

    # extract machine account from tdb file
    my $machine_account = "";
    my $machine_account_key = "SECRETS/SALTING_PRINCIPAL/DES/$dns_name";
    my $tdb_secret_host_value;
    ($exit_code, $tdb_secret_host_value) = tdbdump_get_value("/chroots/$section/var/cache/samba/secrets.tdb", $machine_account_key);
    if ($exit_code == 0 && $tdb_secret_host_value ne "") {
        $machine_account = extract_machine_account($tdb_secret_host_value);
    }

    # extract machine account password from tdb file
    my $machine_password="";
    my $machine_account_password_key = "SECRETS/MACHINE_PASSWORD/$work_group";
    my $tdb_secret_machine_password_value;

    ($exit_code, $tdb_secret_machine_password_value) = tdbdump_get_value("/chroots/$section/var/cache/samba/secrets.tdb", $machine_account_password_key);

    if ($exit_code == 0 && $tdb_secret_machine_password_value ne "") {
        $machine_password = extract_machine_password($tdb_secret_machine_password_value);
    }

    if (!$ini->exists($section, 'machine_account')) {
        $ini->newval($section, 'machine_account', $machine_account);
        $updated |= 1;
    }

    if (!$ini->exists($section, 'machine_account_password')) {
        $ini->newval($section, 'machine_account_password', $machine_password);
        $updated |= 1;
    }
}

if ($updated) {
    $ini->RewriteConfig();
}

sub tdbdump_get_value {
    my ($tdb_file, $key) = @_;
    my $cmd = "/usr/bin/tdbdump $tdb_file -k $key";

    my $result = qx($cmd);
    my $exit_code = $? >> 8;

    return $exit_code, $result;
}

sub extract_machine_account {
    my ($tdb_secret_host_string) = @_;
    if ($tdb_secret_host_string =~ /^host\/(.*?)@(.*?)\\00$/i) {
        my $hostname = $1;
        my $domain = $2;

        # this is a double check to make sure we have valid machine FQDN
        if ($hostname =~ /^(.*?)\.$domain/i) {
            return $1 . '$';
        }
    }
    return "";
}

sub extract_machine_password {
    my ($raw_password) = @_;

    chomp($raw_password);
    $raw_password =~ s/\\00//g;
    $raw_password =~ s/\\//g;
    $raw_password =~ s/\\//g;

    my $bin_data = encode("UTF-16le", decode("UTF-8", pack("H*", $raw_password)));

    my $md4 = Digest::MD4->new;
    $md4->add($bin_data);
    my $hash = $md4->digest;

    return(unpack("H*", $hash));
}


=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2023 Inverse inc.

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