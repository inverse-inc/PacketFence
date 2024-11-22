package pf::constants::firewallsso;

=head1 NAME

pf::constants::firewallsso - constants for firewallsso objects

=cut

=head1 DESCRIPTION

pf::constants::firewallsso

=cut

use strict;
use warnings;
use base qw(Exporter);
use Readonly;

our @EXPORT_OK = qw($SYSLOG_TRANSPORT $HTTP_TRANSPORT $UNKNOWN $API $REEVALUATE $DHCP $ACCOUNTING);

Readonly::Scalar our $SYSLOG_TRANSPORT => "syslog";
Readonly::Scalar our $HTTP_TRANSPORT => "http";
Readonly::Scalar our $UNKNOWN => "unknown";
Readonly::Scalar our $API => "api";
Readonly::Scalar our $REEVALUATE => "reevaluate";
Readonly::Scalar our $DHCP => "DHCP";
Readonly::Scalar our $ACCOUNTING => "accounting";

Readonly::Scalar our $FIREWALL_TYPES => [
    "BarracudaNG",
    "Checkpoint",
    "FortiGate",
    "Iboss",
    "JuniperSRX",
    "PaloAlto",
    "WatchGuard",
    "JSONRPC",
    "LightSpeedRocket",
    "SmoothWall",
    "FamilyZone",
    "CiscoIsePic",
    "ContentKeeper",
];

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2024 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and::or
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


