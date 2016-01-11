=head1 NAME

Test for the pf::Portal::ProfileFactory

=cut

=head1 DESCRIPTION

Test for the pf::Portal::ProfileFactory

=cut

use strict;
use warnings;

use lib '/usr/local/pf/lib';

use Test::More tests => 18;

BEGIN {
    #include test libs
    use lib qw(/usr/local/pf/t);
    #Module for overriding configuration paths
    use PfFilePaths;
    use_ok("pf::Portal::ProfileFactory");
}


#This test will running last
use Test::NoWarnings;

my $profile = pf::Portal::ProfileFactory->instantiate("00:00:00:00:00:00", {});

is($profile->getName, "default");

$profile = pf::Portal::ProfileFactory->instantiate("00:00:00:00:00:00", { last_ip => '192.168.2.1'});

is($profile->getName, "network");

$profile = pf::Portal::ProfileFactory->instantiate("00:00:00:00:00:00", { last_switch => '192.168.1.1'});

is($profile->getName, "switch");

$profile = pf::Portal::ProfileFactory->instantiate("00:00:00:00:00:00", { last_switch => '192.168.1.3', last_port => 1});

is($profile->getName, "switch_port");

$profile = pf::Portal::ProfileFactory->instantiate("00:00:00:00:00:00", { last_connection_type => 'wired'});

is($profile->getName, "connection_type");

$profile = pf::Portal::ProfileFactory->instantiate("00:00:00:00:00:00", { last_ssid => 'SSID'});

is($profile->getName, "ssid");

$profile = pf::Portal::ProfileFactory->instantiate("00:00:00:00:00:00", { last_port => '2'});

is($profile->getName, "port");

$profile = pf::Portal::ProfileFactory->instantiate("00:00:00:00:00:00", { category => 'bob'});

is($profile->getName, "node_role");

$profile = pf::Portal::ProfileFactory->instantiate("00:00:00:00:00:00", { last_vlan => 5});

is($profile->getName, "vlan");

$profile = pf::Portal::ProfileFactory->instantiate("00:00:00:00:00:00", { realm => 'magic'});

is($profile->getName, "realm");

$profile = pf::Portal::ProfileFactory->instantiate("00:00:00:00:00:00", { last_uri => 'captivate'});

is($profile->getName, "uri");

$profile = pf::Portal::ProfileFactory->instantiate("00:00:00:00:00:00", { last_ssid => 'ANYORALL', last_connection_type => 'simple' });

is($profile->getName, "all");

$profile = pf::Portal::ProfileFactory->instantiate("00:00:00:00:00:00", { last_ssid => 'ANYORALL'});

is($profile->getName, "any");

$profile = pf::Portal::ProfileFactory->instantiate("00:00:00:00:00:00", { last_ssid => 'ANY'});

is($profile->getName, "any");

$profile = pf::Portal::ProfileFactory->instantiate("00:00:00:00:00:00", { last_switch => '192.168.1.4'});

is($profile->getName, "switches");

$profile = pf::Portal::ProfileFactory->instantiate("00:00:00:00:00:00", { last_switch => '192.168.1.5'});

is($profile->getName, "switches");

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2015 Inverse inc.

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
