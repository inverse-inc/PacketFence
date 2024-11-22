package pf::constants::switch;

=head1 NAME

pf::constants::switch add documentation

=cut

=head1 DESCRIPTION

pf::constants::switch

=cut

use strict;
use warnings;
use base qw(Exporter);
use Readonly;

our @EXPORT_OK = qw(
    $DEFAULT_ACL_TEMPLATE
);

Readonly::Scalar our $DEFAULT_ACL_TEMPLATE => '${if($allow, "permit", "deny")} $proto ${if($src_host, join(" ", "host", $src_host), "any")} ${if($src_port, join(" ", "eq", $src_port), "")} ${if($dst_host, join(" ", "host", $dst_host), "any")} ${if($dst_port, join(" ", "eq", $dst_port), "")}';

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


