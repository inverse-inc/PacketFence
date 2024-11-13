#!/usr/bin/perl

=head1 NAME

fb -

=head1 DESCRIPTION

fb

=cut

use strict;
use warnings;
use Symbol 'gensym';
use IPC::Open3 qw(open3);
use lib qw(/usr/local/pf/lib);
use lib qw(/usr/local/pf/lib_perl/lib/perl5);
my $collector_binary = "/usr/local/fingerbank/collector/fingerbank-collector";

%ENV = ();
my $pid = open3(
    my $chld_in,
    my $chld_out,
    my $chld_err = gensym,
    $collector_binary,
    '--help',
);
#pop off first line
<$chld_err>;


#BPF Filter for mdns (environment variable: COLLECTOR_FILTER_MDNS_HANDLER) (default "((((ether host 01:00:5E:00:00:FB) and (host 224.0.0.251)) or ((ether host 33:33:00:00:00:FB) and (host FF02::FB))) and (port 5353))")
#

while(<$chld_err>) {
    my $option = $_;
    my $text = <$chld_err>;
    $text =~ s/^\s*//;
    my ($variable, $default, $desc);
    if ($text =~ /(.*?) \(environment variable: (.*?)\)(?: \(default (.*)\))?/) {
        $default = $3 // "";
        $variable = $2;
        $desc = $1;
    }  elsif ($text =~ /(.*?) \(([A-Z0-9_]+) (?:environment|envirionment|envrionment) variable\)(?: \(default (.*)\))?/) {
        $default = $3 // "";
        $variable = $2;
        $desc = $1;
    }

    next if !defined $variable;
    $default =~ s/^"//;
    $default =~ s/"$//;
    print qq{
#$text
#$desc
$variable=$default
};
}


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

