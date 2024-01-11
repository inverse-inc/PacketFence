#!/usr/bin/perl

=head1 NAME

to-7.1-authentication-conf

=cut

=head1 DESCRIPTION

Add default required fields for SQL Twilio and SMS sources

=cut

use strict;
use warnings;
use lib qw(/usr/local/pf/lib /usr/local/pf/lib_perl/lib/perl5);
use Config::IniFiles;
use pf::util qw(run_as_pf);
use pf::file_paths qw(
    $authentication_config_file
    $pf_config_file
);


my $pf_ini = Config::IniFiles->new(-file => $pf_config_file, -allowempty => 1);

my %ldap_attributes = map { $_ => 1 } (
    qw(
  uid cn sAMAccountName servicePrincipalName UserPrincipalName department displayName distinguishedName givenName memberOf sn eduPersonPrimaryAffiliation mail postOfficeBox description groupMembership basedn dNSHostName
    ),
    (
        split(/\s*,\s*/, $pf_ini->val('advanced','ldap_attributes', ''))
    )
);

use Data::Dumper;print Dumper(\%ldap_attributes);

#run_as_pf();

my $file = $authentication_config_file;

if (@ARGV) {
    $file = $ARGV[0];
}

my %TYPES = map { $_ => 1} qw (AD EDIR LDAP GoogleWorkspaceLDAP);

my $cs = Config::IniFiles->new(-file => $file, -allowempty => 1);
my $update = 0;
for my $section ($cs->Sections()) {
    next unless $section =~ /(.*?) rule (.*)$/;
    my $parent_id = $1;
    my $type = $cs->val($parent_id, 'type');
    next if !defined $type || !exists $TYPES{$type};
    print "'$parent_id' : $section\n";
    for my $param (grep { /^condition\d+$/} $cs->Parameters($section)) {
        my $val = $cs->val($section, $param);
        my ($attr, $op, $v) = split(',', $val, 3);
        if (exists $ldap_attributes{$attr}) {
            my $updated = join(',', "ldap:$attr", $op, $v);
            print "$attr updated to $updated\n";
            $cs->setval($section, $param, $updated);
            $update |= 1;
        }
    }
}

if ($update) {
    $cs->RewriteConfig() || die "Unable to update file" . join("\n", @Config::IniFiles::errors);
    print "All done\n";
    exit 0;
}


print "Nothing to be done\n";

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

