#!/usr/bin/perl

=head1 NAME

Test for the pf::Portal::Profile

=cut

=head1 DESCRIPTION

Test for the pf::Portal::Profile

=cut

use strict;
use warnings;

BEGIN {
    #include test libs
    use lib qw(/usr/local/pf/t);
    #Module for overriding configuration paths
    use setup_test_config;
}

use Test::More tests => 12;
use Test::Exception;
use JSON::MaybeXS;
use_ok("pf::Connection::ProfileFactory");

our $JSON = JSON->new->convert_blessed(1);

my $profile = pf::Connection::ProfileFactory->instantiate("00:00:00:00:00:00", {});

lives_ok { $JSON->encode($profile) } "Profile can be serialized to json";;

# scanners
is($profile->findScan("00:00:00:00:00:00", {device_type => "Microsoft Windows Kernel 6.0", category => "guest"})->{_id}, "test1",
    "Matching scan properly when OS + category match");

is($profile->findScan("00:00:00:00:00:00", {device_type => "Microsoft Windows Kernel 6.0", category => "dummy"})->{_id}, "test2",
    "Matching scan properly when scan defines only OS");

is($profile->findScan("00:00:00:00:00:00", {device_type => undef, category => "guest"})->{_id}, "test3",
    "Matching scan properly when scan defines only category");

is($profile->findScan("00:00:00:00:00:00", {device_type => undef, category => "dummy"})->{_id}, "test4",
    "Matching scan properly when scan defines no OS nor category");

isnt($profile->findScan("00:00:00:00:00:00", {device_type => undef, category => "guest"})->{_id}, "test1",
    "Shouldn't match because OS is undef");

# provisionners
is($profile->findProvisioner("00:00:00:00:00:00", {device_type => "Microsoft Windows Kernel 6.0", category => "guest"})->id, "deny1",
    "Matching provisioner properly when OS + category match");

is($profile->findProvisioner("00:00:00:00:00:00", {device_type => "Microsoft Windows Kernel 6.0", category => "dummy"})->id, "deny2",
    "Matching provisioner properly when provisioner defines only OS");

is($profile->findProvisioner("00:00:00:00:00:00", {device_type => "Playstation 4", category => "guest"})->id, "deny3",
    "Matching provisioner properly when provisioner defines only category");

is($profile->findProvisioner("00:00:00:00:00:00", {device_type => "Playstation 4", category => "dummy"})->id, "deny4",
    "Matching provisioner properly when provisioner defines no OS nor category");

is($profile->findProvisioner("00:00:00:00:00:00", {device_type => undef, category => "guest"}), undef,
    "Shouldn't find a provisioner when there is no OS defined.");

done_testing();

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

