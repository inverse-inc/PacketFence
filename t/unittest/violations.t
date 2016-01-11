#!/usr/bin/perl
=head1 NAME

example pf test

=cut

=head1 DESCRIPTION

example pf test script

=cut

use strict;
use warnings;
#
use lib '/usr/local/pf/lib';

use Test::More tests => 20;

BEGIN {
    #include test libs
    use lib qw(/usr/local/pf/t);
    #Module for overriding configuration paths
    use PfFilePaths;
}

use_ok('pf::violation');

# Will be able to match a violation with multiple triggers by only passing the trigger info
my @violations = $pf::violation::VIOLATION_FILTER_ENGINE->match_all({device_id => 2});
is(@violations, 1);
is($violations[0], "1100009");

# Will be able to match a violation with multiple data that will all trigger it
@violations = $pf::violation::VIOLATION_FILTER_ENGINE->match_all({device_id => 2, dhcp_fingerprint_id => 3});
is(@violations, 1);
is($violations[0], "1100009");

# Will be able to match a violation with multiple data when only a part will match
@violations = $pf::violation::VIOLATION_FILTER_ENGINE->match_all({device_id => 2, dhcp_fingerprint_id => "dinde"});
is(@violations, 1);
is($violations[0], "1100009");

# Will be able to match multiple violations on the same trigger
@violations = $pf::violation::VIOLATION_FILTER_ENGINE->match_all({last_detect_id => 1});
is(@violations, 2);
is($violations[0], "1100009");
is($violations[1], "1100008");

# Will be able to match multiple violations on the different triggers
@violations = $pf::violation::VIOLATION_FILTER_ENGINE->match_all({last_detect_id => 2, device_id => 3});
is(@violations, 2);
is($violations[0], "1100007");
is($violations[1], "1100008");

# Will be able to match a mac trigger that uses a regex
@violations = $pf::violation::VIOLATION_FILTER_ENGINE->match_all({mac => "12:34:56:78:90:12"});
is(@violations, 1);
is($violations[0], "1100009");

# Will not be able to match on a disabled violation
@violations = $pf::violation::VIOLATION_FILTER_ENGINE->match_all({last_detect_id => -1});
is(@violations, 0);

# Can match a combined trigger
@violations = $pf::violation::VIOLATION_FILTER_ENGINE->match_all({last_detect_id => 10, mac => "21:34:56:78:90:12"});
is(@violations, 1);
is($violations[0], "1100011");

# Can't match a part of a combined trigger
@violations = $pf::violation::VIOLATION_FILTER_ENGINE->match_all({last_detect_id => 9, mac => "21:34:56:78:90:12"});
is(@violations, 0);


#This test will running last
use Test::NoWarnings;

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
