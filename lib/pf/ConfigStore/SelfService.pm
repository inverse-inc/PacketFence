package pf::ConfigStore::SelfService;
=head1 NAME

pf::ConfigStore::SelfService add documentation

=cut

=head1 DESCRIPTION

pf::ConfigStore::SelfService

=cut

use strict;
use warnings;
use Moo;
use pf::file_paths qw($self_service_config_file $self_service_default_config_file);
use pf::util;
use pf::constants;
extends 'pf::ConfigStore';
with 'pf::ConfigStore::Role::ReverseLookup';

sub configFile { $self_service_config_file };

sub importConfigFile { $self_service_default_config_file }

sub pfconfigNamespace {'config::SelfService'}

=head2 canDelete

canDelete

=cut

sub canDelete {
    my ($self, $id) = @_;
    if ($self->isInProfile('self_service', $id)) {
        return "Used in a profile", $FALSE;
    }

    return $self->SUPER::canDelete($id);
}

=head2 cleanupAfterRead

Clean up data

=cut

sub cleanupAfterRead {
    my ($self, $id, $data) = @_;
    $self->expand_list($data, $self->_fields_expanded);
}

=head2 cleanupBeforeCommit

Clean data before update or creating

=cut

sub cleanupBeforeCommit {
    my ($self, $id, $data) = @_;
    my $real_id = $self->_formatSectionName($id);
    my $config = $self->cachedConfig;
    # Clear the section of any previous values
    $config->ClearSection($real_id);
    $self->flatten_list($data, $self->_fields_expanded);
}

=head2 _fields_expanded

=cut

sub _fields_expanded {
    return qw(device_registration_allowed_devices roles_allowed_to_unregister device_registration_roles);
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

