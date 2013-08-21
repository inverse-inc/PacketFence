#!/usr/bin/perl
=head1 NAME

autentication

=cut

=head1 DESCRIPTION

autentication

=cut

use strict;
use warnings;

use Test::More tests => 5;                      # last test to print

use Test::NoWarnings;
use diagnostics;
BEGIN {
    use lib '/usr/local/pf/lib';
    use PfFilePaths;
}


# pf core libs

use_ok("pf::authentication");

is(pf::authentication::match("bad_source_name",{ username => 'test' }),undef,"Return undef for an invalid name of source");

is_deeply(
    pf::authentication::match("email",{ username => 'test' }),
    [
        pf::Authentication::Action->new({
            'value' => 'guest',
            'type' => 'set_role'
        }),
        pf::Authentication::Action->new({
            'value' => '1D',
            'type' => 'set_access_duration'
        })
    ],
    "match all email actions"
);

is_deeply(
    pf::authentication::match("htpasswd1",{ username => 'user_manager' }),
    [
        pf::Authentication::Action->new({
            'value' => 'User Manager',
            'type' => 'set_access_level'
        })
    ],
    "match htpasswd1 by username"
);


=head1 AUTHOR

Inverse inc. <info@inverse.ca>

Minor parts of this file may have been contributed. See CREDITS.

=head1 COPYRIGHT

Copyright (C) 2005-2013 Inverse inc.

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


