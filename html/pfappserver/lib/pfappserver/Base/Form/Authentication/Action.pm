package pfappserver::Base::Form::Authentication::Action;

=head1 NAME

pfappserver::Base::Form::Rule - Common Web form parameters related to user rules

=head1 DESCRIPTION

Common form definition to define actions related to a user or a users source.
This form is intended to be used along other forms (User::Create,
Authentication::Rule).

=cut

use HTML::FormHandler::Moose;
extends 'pfappserver::Base::Form';
with qw(
    pfappserver::Base::Form::Role::AllowedOptions
    pfappserver::Role::Form::RolesAttribute
);

use HTTP::Status qw(:constants is_success);
use List::MoreUtils qw(uniq);
use pf::config qw(%Config %ConfigMfa);
use pf::web::util;
use pf::Authentication::constants;
use pf::Authentication::Action;
use pf::admin_roles;
use pf::log;
use pf::constants::config qw($TIME_MODIFIER_RE);

has 'source_type' => ( is => 'ro' );

# Form fields
has_field 'actions' =>
  (
   type => 'Repeatable',
   num_extra => 1, # add extra row that serves as a template
  );
has_field 'actions.type' =>
  (
   type => 'Select',
   widget_wrapper => 'None',
   localize_labels => 1,
   options_method => \&options_actions,
  );
has_field 'actions.value' =>
  (
   type => 'Hidden',
   required => 1,
   messages => { required => 'Make sure all the actions are properly defined.' },
   deflate_value_method => sub {
     my ( $self, $value ) = @_;
     return ref($value) ? join(",",@{$value}) : $value ;
   },
  );


our %ACTION_FIELD_OPTIONS = (
    $Actions::MARK_AS_SPONSOR => {
        type    => 'Hidden',
        default => '1'
    },
    $Actions::SET_ACCESS_DURATIONS => {
        type           => 'Select',
        do_label       => 0,
        wrapper        => 0,
        multiple       => 1,
        element_class => ['chzn-select'],
        element_attr => {'data-placeholder' => 'Click to add an access duration'},
        options_method => \&options_durations,
    },
    $Actions::SET_ACCESS_LEVEL => {
        type          => 'Select',
        do_label      => 0,
        wrapper       => 0,
        multiple      => 1,
        element_class => ['chzn-select'],
        element_attr => {'data-placeholder' => 'Click to add an access right'},
        options_method => \&options_access_level,
    },
    $Actions::SET_ROLE => {
        type           => 'Select',
        do_label       => 0,
        wrapper        => 0,
        element_class => ['chzn-deselect'],
        options_method => \&options_roles,
    },
    $Actions::SET_ACCESS_DURATION => {
        type           => 'Select',
        do_label       => 0,
        wrapper        => 0,
        options_method => \&options_durations,
        default_method => sub { $Config{'guests_admin_registration'}{'default_access_duration'} }
    },
    $Actions::SET_UNREG_DATE => {
        type     => 'DatePicker',
        do_label => 0,
        wrapper  => 0,
    },
    $Actions::SET_TIME_BALANCE => {
        type           => 'Select',
        do_label       => 0,
        wrapper        => 0,
        options_method => \&options_durations_absolute,
        default_method => sub { $Config{'guests_admin_registration'}{'default_access_duration'} }
    },
    $Actions::SET_BANDWIDTH_BALANCE => {
        type           => 'Text',
        do_label       => 0,
        wrapper        => 0,
    },
    $Actions::SET_ROLE_FROM_SOURCE => {
        type           => 'Select',
        do_label       => 0,
        wrapper        => 0,
        element_class => ['chzn-deselect'],
        options_method => \&options_set_role_from_source,
    },
    $Actions::TRIGGER_RADIUS_MFA => {
        type           => 'Select',
        do_label       => 0,
        wrapper        => 0,
        element_class => ['chzn-deselect'],
        options_method => \&options_trigger_radius_mfa,
    },
    $Actions::TRIGGER_PORTAL_MFA => {
        type           => 'Select',
        do_label       => 0,
        wrapper        => 0,
        element_class => ['chzn-deselect'],
        options_method => \&options_trigger_portal_mfa,
    },
);

=head2 field_list

Dynamically build the list of available actions corresponding to the
authentication source type.

=cut

sub field_list {
    my $self = shift;

    my ($classname, $actions_ref, @fields);

    $classname = 'pf::Authentication::Source::' . $self->form->source_type . 'Source';
    eval "require $classname";
    if ($@) {
        $self->form->ctx->log->error($@);
    }
    else {
        @fields = map { exists $ACTION_FIELD_OPTIONS{$_} ? ( "${_}_action" => $ACTION_FIELD_OPTIONS{$_}) : () } @{$classname->available_actions()};
    }

    return \@fields;
}

=head2 options_actions

Populate the actions select field with the available actions of the
authentication source.

=cut

sub options_actions {
    my $self = shift;

    my ($classname, $actions_ref, @actions);

    $classname = 'pf::Authentication::Source::' . $self->form->source_type . 'Source';
    eval "require $classname";
    if ($@) {
        $self->form->ctx->log->error($@);
    }
    else {
        my @allowed_actions = $self->form->_get_allowed_options('allowed_actions');
        unless (@allowed_actions) {
            @allowed_actions = @{$classname->available_actions()};
        }
        @actions = map { 
          { value => $_, 
            label => $self->_localize($_), 
            attributes => { 'data-rule-class' => pf::Authentication::Action->getRuleClassForAction($_) } 
          } 
        } @allowed_actions;
    }

    return @actions;
}

=head2 options_access_level

Populate the select field for the 'access level' template action.

=cut

sub options_access_level {
    my ($self) = @_;
    return map { { value => $_, label => $_ } } $self->form->allowed_access_levels();
}

=head2 options_roles

Populate the select field for the roles template action.

=cut

sub options_roles {
    my $self = shift;
    my @options_values = $self->form->_get_allowed_options('allowed_roles');
    unless( @options_values ) {
        my $result = $self->form->roles;
        @options_values = map { $_->{name} } @$result;
    }
    # Build a list of existing roles
    return map { { value => $_, label => $_ } } @options_values;
}

=head2 options_durations

Populate the access duration select field with the available values defined
in the pf.conf configuration file.

=cut

sub options_durations {
    my $self = shift;
    my $form = $self->form;
    my @options_values = $form->_get_allowed_options('allowed_access_durations');
    if (@options_values) {
        return make_durations_options($form, \@options_values);
    };

    my $default_choices = $Config{'guests_admin_registration'}{'access_duration_choices'};
    my @choices = uniq admin_allowed_options_all([$form->user_roles],'allowed_access_durations'), split (/\s*,\s*/, $default_choices);
    return make_durations_options($form, \@choices);
}

=head2 make_durations_options

make_durations_options

=cut

sub make_durations_options {
    my ($form, $choices) = @_;
    my $durations = pf::web::util::get_translated_time_array(
        $choices,
        $form->languages()->[0]
    );

    return map { {value => $_->[1], label => $_->[2]} } sort { $a->[0] <=> $b->[0] } @$durations;
}

=head2 options_durations_absolute

Populate the absolute access duration select field with the available values defined
in the pf.conf configuration file.

=cut

sub options_durations_absolute {
    my $self = shift;
    my $form = $self->form;
    my @options_values = grep { $_ =~ /^(\d+)($TIME_MODIFIER_RE)$/} $form->_get_allowed_options('allowed_access_durations');
    if (@options_values) {
        return make_durations_options($form, \@options_values);
    };

    my $default_choices = $Config{'guests_admin_registration'}{'access_duration_choices'};
    my @choices = grep { $_ =~ /^(\d+)($TIME_MODIFIER_RE)$/} uniq admin_allowed_options_all([$form->user_roles],'allowed_access_durations'), split (/\s*,\s*/, $default_choices);
    return make_durations_options($form, \@choices);
}

=head2 options_set_role_from_source

retrive the realms

=cut

sub options_set_role_from_source {
    my ($self) = @_;
    my $form = $self->form;
    if ($form->can('_options_set_role_from_source')) {
        return $form->_options_set_role_from_source();
    }

    return map { $_ => $_} @{$Config{advanced}->{ldap_attributes}};
}


=head2 options_trigger_portal_mfa

retrieve mfa config

=cut

sub options_trigger_portal_mfa {
    my ($self) = @_;

    return map { $_ => $_} grep {$ConfigMfa{$_}->{"scope"} =~ /Portal/i } keys %ConfigMfa;

}

=head2 options_trigger_radius_mfa

retrieve mfa config

=cut

sub options_trigger_radius_mfa {
    my ($self) = @_;

    return map { $_ => $_} grep {$ConfigMfa{$_}->{"scope"} =~ /Radius/i } keys %ConfigMfa;

}


=head2 validate

Validate that each action is defined only once.

=cut

sub validate {
    my $self = shift;

    my %actions;
    foreach my $action (@{$self->value->{actions}}) {
        $actions{$action->{type}}++;
    }
    my @duplicates = grep { $actions{$_} > 1 } keys %actions;
    if (scalar @duplicates > 0) {
        $self->field('actions')->add_error("You can't have more than one action of the same type.");
    }
    foreach my $action (@{$self->value->{actions}}) {
        get_logger->info($action->{type});
    }
}

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

__PACKAGE__->meta->make_immutable unless $ENV{"PF_SKIP_MAKE_IMMUTABLE"};
1;
