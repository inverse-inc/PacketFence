#!/usr/bin/perl

=head1 NAME

profile/filter/includes.t

=cut

=head1 DESCRIPTION

=cut

use strict;
use warnings;

BEGIN {
    use lib qw(/usr/local/pf/t);
    use setup_test_config;
}

use Test::More tests => 6;                      # last test to print

use Test::NoWarnings;

use_ok("pf::condition::includes");

my $filter = new_ok ( "pf::condition::includes", [value => 'test'],"Test include based filter");

ok($filter->match(['test','testing123']),"filter matches");

ok(!$filter->match(['desting','testing123']),"filter does not match when it's doesn't include element");

ok(!$filter->match(undef),"value undef does not match filter");

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


