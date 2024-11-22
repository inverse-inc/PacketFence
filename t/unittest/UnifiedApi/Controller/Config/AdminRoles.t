#!/usr/bin/perl

=head1 NAME

AdminRoles

=cut

=head1 DESCRIPTION

unit test for AdminRoles

=cut

use strict;
use warnings;

BEGIN {
    #include test libs
    use lib qw(/usr/local/pf/t);
    #Module for overriding configuration paths
    use setup_test_config;
}

use pf::ConfigStore::AdminRoles;
use Test::More tests => 14;
use Test::Mojo;
use Utils;

my ($fh, $filename) = Utils::tempfileForConfigStore("pf::ConfigStore::AdminRoles");

#This test will running last
use Test::NoWarnings;
my $t = Test::Mojo->new('pf::UnifiedApi');

my $collection_base_url = '/api/v1/config/admin_roles';

my $base_url = '/api/v1/config/admin_role';

$t->get_ok($collection_base_url)
  ->status_is(200);

$t->post_ok($collection_base_url => json => {})
  ->status_is(422);

$t->post_ok($collection_base_url, {'Content-Type' => 'application/json'} => '{')
  ->status_is(400);

$t->get_ok("$base_url/User Manager")
  ->status_is(200)
  ->json_is('/item/id', 'User Manager');

$t->patch_ok("$base_url/User Manager" => json => { allowed_access_durations => '1h,3h,12h,1D,2D,3D,5D', })
  ->status_is(200);

$t->patch_ok("$base_url/User Manager" => json => { allowed_access_durations => '1h,3h,12h,1D,2D,3D,5d', })
  ->status_is(422);

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

