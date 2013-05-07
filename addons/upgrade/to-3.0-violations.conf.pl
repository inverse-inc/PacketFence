#!/usr/bin/perl

=head1 NAME

to-3.0-violations.conf.pl - 3.0 upgrade script for conf/violations.conf

=head1 USAGE

Basically: 

  addons/upgrade/to-3.0-violations.conf.pl < conf/violations.conf > violations.conf.new

Then look at violations.conf.new and if it's ok, replace your conf/violations.conf with it.

=head1 DESCRIPTION

Replaces disable=value into enabled=!value.

=cut
use strict;
use warnings;

while (<>) {
    if (/^disable=(.*)$/i) {
        print "enabled=", ( $1 =~ /[yY]/ ? 'N' : 'Y' ), "\n";
    } else {
        print;
    }
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

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

# vim: set shiftwidth=4:
# vim: set expandtab:
# vim: set backspace=indent,eol,start:

