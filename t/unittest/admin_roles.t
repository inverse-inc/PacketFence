=head1 NAME

admin_roles

=cut

=head1 DESCRIPTION

admin_roles

=cut

use strict;
use warnings;
BEGIN {
    use lib qw(/usr/local/pf/t /usr/local/pf/lib);
    use PfFilePaths;
}

use Test::More tests => 5;                      # last test to print

use Test::NoWarnings;

use_ok("pf::admin_roles");

ok(admin_can(["User Manager"],'USERS_CREATE'),"User Manager can create a user");

ok(!admin_can(["User Manager"],'NODES_READ'),"User Manager cannot read a node");

ok(admin_can(["ALL"],'USERS_CREATE'),"ALL can create a user");

 
=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2014 Inverse inc.

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


