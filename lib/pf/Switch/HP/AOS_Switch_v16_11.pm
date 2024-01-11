package pf::Switch::HP::AOS_Switch_v16_11;

=head1 NAME

pf::Switch::HP::Procurve_5400

=head1 SYNOPSIS

Module to manage HP Procurve 5400 switches

=head1 STATUS

=over

=item Supports

=over

=item linkUp / linkDown mode

=item port-security

=item MAC-Authentication

=item 802.1X

=back

=back

Has been reported to work on 5412zl by the community

=head1 BUGS AND LIMITATIONS

The code is the same as the 2500 but the configuration should be like the 4100 series.

Recommanded Firmware is K.15.06.0008

=head1 SNMP

This switch can parse SNMP traps and change a VLAN on a switch port using SNMP.

=cut

use strict;
use warnings;
use Net::SNMP;

use base ('pf::Switch::HP::AOS_Switch_v16_10');

use pf::constants;
use pf::config qw(
    $MAC
    $PORT
);
use pf::Switch::constants;
use pf::util;

sub description { 'AOS Switch v16.11' }

# CAPABILITIES
# access technology supported
# VoIP technology supported
use pf::SwitchSupports qw(
    WiredMacAuth
    WiredDot1x
    RadiusVoip
);
# inline capabilities
sub inlineCapabilities { return ($MAC,$PORT); }

#Insert your voice vlan name, not the ID.
our $VOICEVLANAME = "voip";

=over

=item getVoipVSA

Get Voice over IP RADIUS Vendor Specific Attribute (VSA).

TODO: Use Egress-VLANID instead. See: http://wiki.freeradius.org/HP#RFC+4675+%28multiple+tagged%2Funtagged+VLAN%29+Assignment

=cut

sub getVoipVsa {
    my ($self) = @_;
    my $logger = $self->logger;

    return ('Egress-VLAN-Name' => "1".$VOICEVLANAME);
}

=item isVoIPEnabled

Is VoIP enabled for this device

=cut

sub isVoIPEnabled {
    my ($self) = @_;
    return ( $self->{_VoIPEnabled} == 1 );
}

=back

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2023 Inverse inc.

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

# vim: set shiftwidth=4:
# vim: set expandtab:
# vim: set backspace=indent,eol,start:
