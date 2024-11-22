package pf::UnifiedApi::Controller::Config::Sources;

=head1 NAME

pf::UnifiedApi::Controller::Config::Sources - 

=cut

=head1 DESCRIPTION

pf::UnifiedApi::Controller::Config::Sources

=cut

use strict;
use warnings;
use pf::authentication;
use HTTP::Status qw(:constants :is);
use Mojo::Base qw(pf::UnifiedApi::Controller::Config::Subtype);

has 'config_store_class' => 'pf::ConfigStore::Source';
has 'form_class' => 'pfappserver::Form::Config::Source';
has 'primary_key' => 'source_id';

use pf::ConfigStore::Source;
use pfappserver::Form::Config::Source;
use pfappserver::Form::Config::Source::AdminProxy;
use pfappserver::Form::Config::Source::AD;
use pfappserver::Form::Config::Source::AzureAD;
use pfappserver::Form::Config::Source::Blackhole;
use pfappserver::Form::Config::Source::Authorization;
use pfappserver::Form::Config::Source::Clickatell;
use pfappserver::Form::Config::Source::EAPTLS;
use pfappserver::Form::Config::Source::Eduroam;
use pfappserver::Form::Config::Source::EDIR;
use pfappserver::Form::Config::Source::Email;
use pfappserver::Form::Config::Source::Facebook;
use pfappserver::Form::Config::Source::Github;
use pfappserver::Form::Config::Source::Google;
use pfappserver::Form::Config::Source::GoogleWorkspaceLDAP;
use pfappserver::Form::Config::Source::Htpasswd;
use pfappserver::Form::Config::Source::HTTP;
use pfappserver::Form::Config::Source::Kerberos;
use pfappserver::Form::Config::Source::Kickbox;
use pfappserver::Form::Config::Source::LDAP;
use pfappserver::Form::Config::Source::LinkedIn;
use pfappserver::Form::Config::Source::Null;
use pfappserver::Form::Config::Source::OpenID;
use pfappserver::Form::Config::Source::Paypal;
use pfappserver::Form::Config::Source::RADIUS;
use pfappserver::Form::Config::Source::SAML;
use pfappserver::Form::Config::Source::SMS;
use pfappserver::Form::Config::Source::SQL;
use pfappserver::Form::Config::Source::SponsorEmail;
use pfappserver::Form::Config::Source::Stripe;
use pfappserver::Form::Config::Source::Twilio;
use pfappserver::Form::Config::Source::WindowsLive;
use pfappserver::Form::Config::Source::Potd;

our %TYPES_TO_FORMS = (
    map { $_ => "pfappserver::Form::Config::Source::$_" } qw(
      AdminProxy
      AD
      Authorization
      AzureAD
      Blackhole
      Clickatell
      EAPTLS
      Eduroam
      EDIR
      Email
      Facebook
      Github
      Google
      GoogleWorkspaceLDAP
      Htpasswd
      HTTP
      Kerberos
      Kickbox
      LDAP
      LinkedIn
      Null
      OpenID
      Paypal
      Potd
      RADIUS
      SAML
      SMS
      SponsorEmail
      SQL
      Stripe
      Twilio
      WindowsLive
      )
);

sub type_lookup {
    return \%TYPES_TO_FORMS;
}

sub validate_item {
    my ($self, $item) = @_;
    $self->_update_item($item);
    return $self->SUPER::validate_item($item);
}

sub _update_item {
    my ($self, $item) = @_;
    my $type = $item->{type};
    if (defined $type && ($type eq 'LDAP' || $type eq 'AD')) {
        my $val = $item->{host};
        if (defined $val && !ref($val)) {
            $item->{host} = [split(/\s*,\s*/, $val)];
        }
    }
}

=head2 test

test a source configuration

=cut

sub test {
    my ($self) = @_;
    my ($error, $new_data) = $self->get_json;
    if (defined $error) {
        return $self->render_error(400, "Bad Request : $error");
    }

    $self->_update_item($new_data);
    my ($status, $form) = $self->form($new_data);
    if ( is_error($status)) {
        return $self->render_error($status, "Cannot determine the valid type");
    }

    $form->process(params => $new_data, posted => 1);
    if ($form->has_errors) {
        return $self->render_error(422, "Unable to validate", $self->format_form_errors($form));
    }

    my $success = eval {
        my $source = newAuthenticationSource($new_data->{type}, 'test', $form->getSourceArgs());
        my $method = $source->can('test');
        if (!$method) {
            return $self->render_error(405, "$new_data->{type} cannot be tested");
        }

        my ($status, $message) = $source->test();
        if (!$status) {
            return $self->render_error(422, $message);
        }
        return 1;
    };
    if ($@) {
        return $self->render_error(422, "$@");
    }
    if (!$success) {
        return;
    }

    $self->render(status => 200, json => {});
    return;
}

=head2 saml_metadata

saml_metadata

=cut

sub saml_metadata {
    my ($self) = @_;
    my $id = $self->id;
    my $source = pf::authentication::getAuthenticationSource($id);
    if ($source->{type} ne 'SAML') {
        return $self->render_error(405, "$id cannot is not a SAML source");
    }
    my $xml = $source->generate_sp_metadata();
    return $self->render(text => $xml);;
}

sub cleanup_item {
    my ($self, $item) = @_;
    $item = $self->SUPER::cleanup_item($item);
    $item->{class} = pf::authentication::classForType($item->{type});
    return $item;
}

=head2 form_parameters

The form parameters should be overridded

=cut

sub form_parameters {
    [
        inactive => [
            qw(
              connection_operator
              connection_value
              date_operator
              date_value
              ldapattribute_operator
              ldapattribute_value
              mark_as_sponsor_action
              number_operator
              number_value
              set_access_duration_action
              set_access_level_action
              set_bandwidth_balance_action
              set_role_action
              set_time_balance_action
              set_unreg_date_action
              substring_operator
              substring_value
              time_operator
              time_period_operator
              time_period_value
              time_value
              )
        ],
    ]
}

=head2 type_meta_info

type_meta_info

=cut

sub type_meta_info {
    my ($self, $type) = @_;
    my $class = "pf::Authentication::Source::${type}Source";
    return {
        value => $type,
        text => $type,
        class => $class->meta->find_attribute_by_name('class')->default
    };
}

sub options_with_no_type {
    my ($self) = @_;
    my $output = $self->SUPER::options_with_no_type();
    my $types = delete $output->{meta}{type}{allowed};
    my @new_types = grep { $_->{value} ne 'SQL' } @$types;
    $output->{meta}{type}{allowed} = \@new_types;
    return $output;
}

=head2 field_default

Get the default value of a field

=cut

sub field_default {
    my ($self, $field, $inheritedValues, $type) = @_;
    if ($type ne 'array') {
        return $self->SUPER::field_default($field, $inheritedValues, $type);
    }

    if ($field->form->isa("pfappserver::Form::Config::Source::GoogleWorkspaceLDAP") && $field->name eq 'host') {
        return ['ldap.google.com'];
    }

    return [];
}

=head2 fields_to_mask

fields_to_mask

=cut

sub fields_to_mask { qw(password radius_secret client_secret api_key shared_secret_direct shared_secret secret) }

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

