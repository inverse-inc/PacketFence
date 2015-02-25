package pfconfig::namespaces::config::Network;

=head1 NAME

pfconfig::namespaces::config::template

=cut

=head1 DESCRIPTION

pfconfig::namespaces::config::template

This module creates the configuration hash associated to somefile.conf

=cut


use strict;
use warnings;

use pfconfig::namespaces::config;
use Data::Dumper;
use pfconfig::log;
use pf::file_paths;
use pf::constants::config;

use base 'pfconfig::namespaces::config';

sub init {
  my ($self) = @_;
  $self->{file} = $network_config_file;
  $self->{child_resources} = [
    'interfaces::routed_isolation_nets',
    'interfaces::routed_registration_nets',
    'interfaces::inline_nets',
  ]
}

sub build_child {
    my ($self) = @_;

    my %ConfigNetworks = %{$self->{cfg}}; 

    my ($config) = @_;
    $self->cleanup_whitespaces(\%ConfigNetworks);

    foreach my $network ( keys %ConfigNetworks ) {
        # transition pf_gateway to next_hop
        # TODO we can deprecate pf_gateway in 2012
        if ( defined($ConfigNetworks{$network}{'pf_gateway'}) && !defined($ConfigNetworks{$network}{'next_hop'}) ) {
            # carry over the parameter so that things still work
            $ConfigNetworks{$network}{'next_hop'} = $ConfigNetworks{$network}{'pf_gateway'};
        }
    }

    $self->{cfg} = \%ConfigNetworks;

    return \%ConfigNetworks;

}

=item is_network_type_vlan_reg

Returns true if given network is of type vlan-registration and false otherwise.

=cut

sub is_network_type_vlan_reg {
    my ($type) = @_;

    my $result = get_network_type($type);
    if (defined($result) && $result eq $pf::constants::config::NET_TYPE_VLAN_REG) {
        return 1;
    } else {
        return 0;
    }
}

=item is_network_type_vlan_isol

Returns true if given network is of type vlan-isolation and false otherwise.

=cut

sub is_network_type_vlan_isol {
    my ($type) = @_;

    my $result = get_network_type($type);
    if (defined($result) && $result eq $pf::constants::config::NET_TYPE_VLAN_ISOL) {
        return 1;
    } else {
        return 0;
    }
}

=item is_network_type_inline

Returns true if given network is of type inline and false otherwise.

=cut

sub is_network_type_inline {
    my ($type) = @_;

    my $result = get_network_type($type);
    if (defined($result) && $result eq $pf::constants::config::NET_TYPE_INLINE) {
        return 1;
    } else {
        return 0;
    }
}

sub get_network_type {
    my ($type) = @_;

    if (!defined($type)) {
        # not defined
        return;
    } elsif ($type =~ /^$pf::constants::config::NET_TYPE_VLAN_REG$/i) {
        # vlan-registration
        return $pf::constants::config::NET_TYPE_VLAN_REG;

    } elsif ($type =~ /^$pf::constants::config::NET_TYPE_VLAN_ISOL$/i) {
        # vlan-isolation
        return $pf::constants::config::NET_TYPE_VLAN_ISOL;

    } elsif (is_type_inline($type)) {
        # inline
        return $pf::constants::config::NET_TYPE_INLINE;

    } elsif ($type =~ /^registration$/i) {
        # deprecated registration
        return $pf::constants::config::NET_TYPE_VLAN_REG;

    } elsif ($type =~ /^isolation$/i) {
        # deprecated isolation
        return $pf::constants::config::NET_TYPE_VLAN_ISOL;
    }

    return;
}

=back

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

# vim: set shiftwidth=4:
# vim: set expandtab:
# vim: set backspace=indent,eol,start:

