package pf::ConfigStore::BillingTiers;
=head1 NAME

pf::ConfigStore::BillingTiers

=cut

=head1 DESCRIPTION

pf::ConfigStore::BillingTiers

=cut

use strict;
use warnings;
use Moo;
use pf::constants;
use pf::file_paths qw($billing_tiers_config_file);
extends 'pf::ConfigStore';
with 'pf::ConfigStore::Role::ReverseLookup';

sub configFile { $billing_tiers_config_file };

sub pfconfigNamespace {'config::BillingTiers'}

=head2 canDelete

canDelete

=cut

sub canDelete {
    my ($self, $id) = @_;
    if ($self->isInProfile('billing_tiers', $id)) {
        return "Used in a profile", $FALSE;
    }

    return $self->SUPER::canDelete($id);
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

1;

