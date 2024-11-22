#!/usr/bin/perl

=head1 NAME

person

=head1 DESCRIPTION

unit test for person

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

use pf::person;
use pf::node;
use Test::More tests => 4;

#This test will running last
use Test::NoWarnings;

my $test_pid = "pid_$$";

person_add($test_pid);


for my $mac ("00:00:44:00:00:00", "00:00:45:00:00:00") {
    node_delete($mac);
    node_add($mac, pid => $test_pid);
}

my @nodes = person_nodes($test_pid);

is(scalar @nodes, 2, "Two nodes found");

my $count = person_unassign_nodes($test_pid);
is($count, 2, "Two nodes unassigned");
@nodes = person_nodes($test_pid);

is(scalar @nodes, 0, "Zero nodes found");


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

