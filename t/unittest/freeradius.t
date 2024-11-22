#!/usr/bin/perl

=head1 NAME

freeradius

=head1 DESCRIPTION

unit test for freeradius

=cut

use strict;
use warnings;
#
BEGIN {
    #include test libs
    use lib qw(/usr/local/pf/t);
    #Module for overriding configuration paths
    use setup_test_config;
}

use Test::More tests => 5;
use pf::freeradius;
use pf::SwitchFactory;

#This test will running last
use Test::NoWarnings;
my $timestamp = $$;

my %config = %pf::SwitchFactory::SwitchConfig;
pf::freeradius::freeradius_populate_nas_config(\%config, $timestamp);
my $validation = pf::freeradius::validation_results($timestamp);
ok($validation->{config_valid}, "Config is valid");
$validation = pf::freeradius::validation_results($timestamp + 1);
ok(!$validation->{config_valid}, "Config is not valid");
is($validation->{other_processes}, 1, "One other process detected reloading switches.conf");

$timestamp +=2;
delete $config{'172.16.8.29'};
pf::freeradius::freeradius_populate_nas_config(\%config, $timestamp);
$validation = pf::freeradius::validation_results($timestamp);
ok($validation->{config_valid}, "Config is valid");

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

