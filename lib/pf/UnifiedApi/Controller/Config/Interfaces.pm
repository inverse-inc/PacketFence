package pf::UnifiedApi::Controller::Config::Interfaces;

=head1 NAME

pf::UnifiedApi::Controller::Config::Interfaces -

=cut

=head1 DESCRIPTION

pf::UnifiedApi::Controller::Config::Interfaces

=cut

use strict;
use warnings;
use Mojo::Base 'pf::UnifiedApi::Controller::RestRoute';
use pfappserver::Model::Enforcement;
use pfappserver::Form::Interface::Create;
use pf::UnifiedApi::Controller::Config;
use pf::error qw(is_success);

# Ensure that all fields here are in the interface response as a default or a value that comes from the model
my %FIELDS = (
    additional_listening_daemons => [],
    dhcpd_enabled => undef,
    dns => undef,
    high_availability => undef,
    hwaddr => undef,
    ifindex => undef,
    ipv6_address => undef,
    ipv6_prefix => undef,
    is_running => undef,
    master => undef,
    nat_enabled => undef,
    networks => [],
    reg_network => undef,
    split_network => undef,
    vip => undef,
    vlan => undef,
    coa => undef,
);

my %FIELDS_TO_REMOVE_FROM_UPDATE = (
    hwaddr => undef,
    ifindex => undef,
    is_running => undef,
    master => undef,
    name => undef,
    network => undef,
    network_iseditable => undef,
    vlan => undef,
);

=head2 validate_item

Validate the parameters of an interface based on the context (create/update)

=cut

sub validate_item {
    my ($self, $form, $item) = @_;
    $form = $form->new(types => pfappserver::Model::Enforcement->new->getAvailableTypes("all"));

    $form->process(pf::UnifiedApi::Controller::Config::form_process_parameters_for_validation($self, $item));
    if (!$form->has_errors) {
        return $form->value;
    }

    $self->render_error(422, "Unable to validate", pf::UnifiedApi::Controller::Config::format_form_errors($self, $form));
    return undef;
}

=head2 model

Get the pfappserver model of the interfaces

=cut

sub model {
    require pfappserver::Model::Interface;
    return pfappserver::Model::Interface->new;
}

sub configStore {
    require pf::ConfigStore::Interface;
    return pf::ConfigStore::Interface->new;
}

=head2 list

List all the interfaces

=cut

sub list {
    my ($self) = @_;
    my @items;
    my %interfaces = %{$self->model->get('all')};
    while(my ($id, $data) = each(%interfaces)) {
        $data->{id} = $id;
        push @items, $data;
    }

    $self->render(json => {items => [map { $self->normalize_interface($_) } @items]}, status => 200);
}

=head2 resource

Handler for resource

=cut

sub resource{1}

=head2 normalize_interface

Normalize interface information for JSON rendering

=cut

sub normalize_interface {
    my ($self, $interface) = @_;
    my @bools = qw(is_running network_iseditable);
    $interface->{not_editable} = $interface->{is_running} ? $self->json_false  : $self->json_true;

    for my $bool (@bools) {
        $interface->{$bool} = $interface->{$bool} ? $self->json_true : $self->json_false;
    }


    ($interface->{type}, @{$interface->{additional_listening_daemons}}) = grep { !/high-availability/ } split(',', $interface->{type});
    
    # Ensure all fields have a default value
    while(my ($field, $default) = each(%FIELDS)) {
        $interface->{$field} = $default unless(exists($interface->{$field}));
    }

    return $interface;
}

=head2 format_type

Format the interface type. Used during creation/update of an interface

=cut

sub format_type {
    my ($self, $interface) = @_;
    $interface->{type} = join(",", $interface->{type}, @{$interface->{additional_listening_daemons}});
    return $interface;
}

=head2 get

Get a specific interface

=cut

sub get {
    my ($self) = @_;
    my $interface_id = $self->stash->{interface_id};
    my $interface = $self->model->get($interface_id);
    if(scalar(keys(%{$interface})) > 0) {
        $interface = $interface->{$interface_id};
        $interface = $self->normalize_interface($interface);
        $interface->{id} = $interface_id;
        $self->render(json => {item => $interface}, status => 200);
    }
    else {
        $self->render_error(404, "Interface $interface_id doesn't exist");
    }
}

=head2 id

id

=cut

sub id {
    my ($self) = @_;
    return $self->stash->{interface_id};
}

=head2 create

Create a new virtual interface

=cut
sub create {
    my ($self) = @_;
    my $data = $self->parse_json;
    my $id = $data->{id};
    $data = $self->validate_item("pfappserver::Form::Interface::Create", $data);
    return unless($data);
    my $full_name = $id . "." . $data->{vlan};
    my $model = $self->model;
    
    $self->handle_management_change($data);

    $data = $self->format_type($data);

    my ($status, $result) = $model->create($full_name);
    if (is_success($status)) {
        ($status, $result) = $model->update($full_name, $data);
    }
    $self->render(json => {message => pf::I18N::pfappserver->localize($result)}, status => $status);
}

=head2 update

Update an existing network interface

=cut

sub update {
    my ($self) = @_;
    my $data = $self->parse_json;
    $data = $self->filter_update_fields($data);

    $data = $self->validate_item("pfappserver::Form::Interface", $data);
    return unless($data);
    my $full_name = $self->stash->{interface_id};
    my $model = $self->model;

    $self->handle_management_change($data);

    $data = $self->format_type($data);

    my ($status, $result) = $model->update($full_name, $data);
    $self->render(json => {message => pf::I18N::pfappserver->localize($result)}, status => $status);
}

=head2 handle_management_change

Handle the case where a management interface is being set while another interface is already management.
Since we can only have a single management interface, we need to remove the type from the existing management to prevent a conflict

=cut

sub handle_management_change {
    my ($self, $data) = @_;
    
    if($data->{type} eq "management") {
        my @management_ints = $self->configStore->search_like("type", "management", "id");
        for my $mgmt_int (@management_ints) {
            if($mgmt_int->{id} ne $self->stash->{interface_id}) {
                my $id = delete $mgmt_int->{id};
                $self->log->info("Management interface is currently being changed. Removing management from $id");
                my $cs = $self->configStore;
                $mgmt_int->{type} =~ s/^management,?//g;
                $cs->update($id, $mgmt_int);
                $cs->commit;
            }
        }
    }
}

=head2 filter_update_fields

Remove dynamic fields that are in the response items if they are in the update fields

=cut

sub filter_update_fields {
    my ($self, $data) = @_;

    for my $f (keys(%FIELDS_TO_REMOVE_FROM_UPDATE)) {
        delete $data->{$f};
    }
    return $data;
}

=head2 delete

Delete a virtual interface

=cut

sub delete {
    my ($self) = @_;
    my ($status, $result) = $self->model->delete($self->stash->{interface_id}, "");
    $status = is_success($status) ? 200 : $status;
    $self->render(json => {message => pf::I18N::pfappserver->localize($result)}, status => $status);
}

=head2 up

Put an interface up

=cut

sub up {
    my ($self) = @_;
    my ($status, $result) = $self->model->up($self->stash->{interface_id});
    $self->render(json => {message => pf::I18N::pfappserver->localize($result)}, status => $status);
}

=head2 down

Put an interface down

=cut

sub down {
    my ($self) = @_;
    my ($status, $result) = $self->model->down($self->stash->{interface_id});
    $self->render(json => {message => pf::I18N::pfappserver->localize($result)}, status => $status);
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
