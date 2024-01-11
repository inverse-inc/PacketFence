package pf::Switch::Aruba::CX;

=head1 NAME

pf::Switch::Aruba::CX

=head1 SYNOPSIS

Module to manage rebanded Aruba HP CX Switch

=head1 STATUS

=over

=item Supports

=over

=item MAC-Authentication

=item 802.1X

=item Radius downloadable ACL support

=item Voice over IP

=item Radius CLI Login

=back

=back

Has been reported to work on Aruba CX

=cut

use strict;
use warnings;
use Net::SNMP;

use base ('pf::Switch::Aruba::5400');

use pf::constants;
use pf::config qw(
    $MAC
    $PORT
    $WIRED_802_1X
    $WIRED_MAC_AUTH
);

use pf::Switch::constants;
use pf::util;
use pf::util::radius qw(perform_disconnect perform_coa);
use Try::Tiny;
use pf::locationlog;

sub description { 'Aruba CX Switch' }

# CAPABILITIES
use pf::SwitchSupports qw(
    PushACLs
);

sub radiusDisconnect {
    my ($self, $mac, $add_attributes_ref) = @_;
    my $logger = $self->logger;

    # initialize
    $add_attributes_ref = {} if (!defined($add_attributes_ref));

    if (!defined($self->{'_radiusSecret'})) {
        $logger->warn(
            "Unable to perform RADIUS CoA-Request on $self->{'_ip'}: RADIUS Shared Secret not configured"
        );
        return;
    }
    # Where should we send the RADIUS CoA-Request?
    # to network device by default
    my $nas_port = $self->{'_disconnectPort'} || '3799';
    my $send_disconnect_to = $self->{'_ip'};
    # but if controllerIp is set, we send there
    if (defined($self->{'_controllerIp'}) && $self->{'_controllerIp'} ne '') {
        $logger->info("controllerIp is set, we will use controller $self->{_controllerIp} to perform deauth");
        $send_disconnect_to = $self->{'_controllerIp'};
    }
    # allowing client code to override where we connect with NAS-IP-Address
    $send_disconnect_to = $add_attributes_ref->{'NAS-IP-Address'}
        if (defined($add_attributes_ref->{'NAS-IP-Address'}));

    my $response;
    try {
        my $connection_info = $self->radius_deauth_connection_info($send_disconnect_to);
        $connection_info->{nas_port} = $nas_port;
        my $locationlog = locationlog_view_open_mac($mac);
        $logger->debug("network device supports roles. Evaluating role to be returned");
        my $roleResolver = pf::roles::custom->instance();
        my $role = $roleResolver->getRoleForNode($mac, $self);

        # transforming MAC to the expected format 00112233CAFE
        my $calling_station_id = uc($mac);
        $calling_station_id =~ s/:/-/g;
        $mac = lc($mac);
        $mac =~ s/://g;

        # Standard Attributes
        my $attributes_ref = {
            'User-Name' => $mac,
            'NAS-IP-Address' => $send_disconnect_to,
            'Calling-Station-Id' => $calling_station_id,
            'NAS-Port' => $locationlog->{port},
        };
        # merging additional attributes provided by caller to the standard attributes
        $attributes_ref = { %$attributes_ref, %$add_attributes_ref };

        if ( $self->shouldUseCoA({role => $role}) ) {

            $attributes_ref = {
                %$attributes_ref,
                'Filter-Id' => $role,
            };
            $logger->info("[$self->{'_ip'}] Returning ACCEPT with role: $role");
            $response = perform_coa($connection_info, $attributes_ref);

        }
        else {
            $response = perform_disconnect($connection_info, $attributes_ref);
        }
    } catch {
        chomp;
        $logger->warn("Unable to perform RADIUS CoA-Request: $_");
        $logger->error("Wrong RADIUS secret or unreachable network device...") if ($_ =~ /^Timeout/);
    };
    return if (!defined($response));

    return $TRUE if ( ($response->{'Code'} eq 'Disconnect-ACK') || ($response->{'Code'} eq 'CoA-ACK') );

    $logger->warn(
        "Unable to perform RADIUS Disconnect-Request."
        . ( defined($response->{'Code'}) ? " $response->{'Code'}" : 'no RADIUS code' ) . ' received'
        . ( defined($response->{'Error-Cause'}) ? " with Error-Cause: $response->{'Error-Cause'}." : '' )
    );
    return;
}

sub wiredeauthTechniques {
    my ($self, $method, $connection_type) = @_;
    my $logger = $self->logger;
    if ($connection_type == $WIRED_802_1X) {
        my $default = $SNMP::SNMP;
        my %tech = (
            $SNMP::SNMP => 'dot1xPortReauthenticate',
            $SNMP::RADIUS => 'deauthenticateMacRadius',
        );

        if (!defined($method) || !defined($tech{$method})) {
            $method = $default;
        }
        return $method,$tech{$method};
    }
    if ($connection_type == $WIRED_MAC_AUTH) {
        my $default = $SNMP::SNMP;
        my %tech = (
            $SNMP::SNMP => 'handleReAssignVlanTrapForWiredMacAuth',
            $SNMP::RADIUS => 'deauthenticateMacRadius',
        );

        if (!defined($method) || !defined($tech{$method})) {
            $method = $default;
        }
        return $method,$tech{$method};
    }
}

=head2 deauthenticateMacRadius

Method to deauth a wired node with CoA.

=cut

sub deauthenticateMacRadius {
    my ($self, $ifIndex,$mac) = @_;
    my $logger = $self->logger;


    # perform CoA
    $self->radiusDisconnect($mac);
}

=head2 acl_chewer

Format ACL to match with the expected switch format.

=cut

sub acl_chewer {
    my ($self, $acl, $role) = @_;
    my $logger = $self->logger;
    my ($acl_ref , @direction) = $self->format_acl($acl);

    my $i = 0;
    my $acl_chewed;
    foreach my $acl (@{$acl_ref->{'packetfence'}->{'entries'}}) {
        $acl->{'protocol'} =~ s/\(\d*\)//;
        my $dest;
        if ($acl->{'destination'}->{'ipv4_addr'} eq '0.0.0.0') {
            $dest = "any";
        } elsif($acl->{'destination'}->{'ipv4_addr'} ne '0.0.0.0') {
            if ($acl->{'destination'}->{'wildcard'} ne '0.0.0.0') {
                $dest = $acl->{'destination'}->{'ipv4_addr'}."/".norm_net_mask($acl->{'destination'}->{'wildcard'});
            } else {
                $dest = $acl->{'destination'}->{'ipv4_addr'};
            }
        }
        my $src;
        if ($acl->{'source'}->{'ipv4_addr'} eq '0.0.0.0') {
            $src = "any";
        } elsif($acl->{'source'}->{'ipv4_addr'} ne '0.0.0.0') {
            if ($acl->{'source'}->{'wildcard'} ne '0.0.0.0') {
                $src = $acl->{'source'}->{'ipv4_addr'}."/".norm_net_mask($acl->{'source'}->{'wildcard'});
            } else {
                $src = $acl->{'source'}->{'ipv4_addr'};
            }
        }
        my $j = $i + 1;
        # Dynamic ACLs and Push ACLs format are different
        if ($self->usePushACLs) {
            $acl_chewed .= ((defined($direction[$i]) && $direction[$i] ne "") ? $direction[$i]."|" : "").$j." ".$acl->{'action'}." ".$acl->{'protocol'}." $src $dest ". ( defined($acl->{'destination'}->{'port'}) ? $acl->{'destination'}->{'port'} : '' ) ."\n";
        } else {
            if ($acl->{'destination'}->{'ipv4_addr'} eq '0.0.0.0') {
                $acl_chewed .= $acl->{'action'}." ".((defined($direction[$i]) && $direction[$i] ne "") ? $direction[$i] : "in")." ".$acl->{'protocol'}." from any to any " . ( defined($acl->{'destination'}->{'port'}) ? $acl->{'destination'}->{'port'} : '' ) ."\n";
            } else {
                $acl_chewed .= $acl->{'action'}." ".((defined($direction[$i]) && $direction[$i] ne "") ? $direction[$i] : "in")." ".$acl->{'protocol'}." from any to ".$acl->{'destination'}->{'ipv4_addr'}." " . ( defined($acl->{'destination'}->{'port'}) ? $acl->{'destination'}->{'port'} : '' ) ."\n";
            }
        }
        $i++;
    }

    return $acl_chewed;
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
