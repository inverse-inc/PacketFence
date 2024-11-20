package pf::UnifiedApi::Controller::Config::Kafka;

=head1 NAME

pf::UnifiedApi::Controller::Config::Kafka -

=head1 DESCRIPTION

pf::UnifiedApi::Controller::Config::Kafka

=cut

use strict;
use warnings;
use pf::error qw(is_error is_success);
use Mojo::Base 'pf::UnifiedApi::Controller::RestRoute';
use pf::UnifiedApi::OpenAPI::Generator::Config;
use pf::UnifiedApi::Controller::Config;
use pfappserver::Form::Config::Kafka;
use pf::ConfigStore::Kafka;
use pf::UnifiedApi::OpenAPI::Generator::Config;
has 'config_store_class' => 'pf::ConfigStore::Kafka';
has 'form_class' => 'pfappserver::Form::Config::Kafka';
has 'openapi_generator_class' => 'pf::UnifiedApi::OpenAPI::Generator::Config';

sub get {
    my ($self) = @_;
    my $item = $self->item;
    return $self->render(json => {item => $item}, status => 200);
}

sub options {
    my ($self) = @_;
}

sub update {
    my ($self) = @_;
    my ($error, $data) = $self->get_json;
    if (defined $error) {
        return $self->render_error(400, "Bad Request : $error");
    }
    my ($status, $new_data, $form) = $self->validate_item($data);
    if (is_error($status)) {
        return $self->render(status => $status, json => $new_data);
    }
    $self->render(status => 200, json => {});
}

sub validate_item {
    my ($self, $item) = @_;
    $item = $self->cleanupItemForValidate($item);
    my ($status, $form) = $self->form($item);
    if (is_error($status)) {
        return $status, { message => $form }, undef;
    }

    $form->process($self->form_process_parameters_for_validation($item));
    if (!$form->has_errors) {
        return 200, $form->value, $form;
    }

    return 422, { message => "Unable to validate", errors => $self->format_form_errors($form) }, undef;
}

=head2 format_form_errors

format_form_errors

=cut

sub format_form_errors {
    my ($self, $form) = @_;
    my $field_errors = $form->field_errors;
    my @errors;
    while (my ($k,$v) = each %$field_errors) {
        push @errors, {field => $k, message => $v};
    }

    return \@errors;
}


sub form_process_parameters_for_validation {
    my ($self, $item) = @_;
    return (posted => 1, params => $item);
}

sub cleanupItemForValidate {
    my ($self, $item) = @_;
    return $item;
}

sub form {
    my ($self, $item, @args) = @_;
    my $form = $self->form_class->new(@args, user_roles => $self->stash->{'admin_roles'});
    return 200, $form;
}

sub config_store {
    my ($self) = @_;
    $self->config_store_class->new;
}

our %fields = (
    iptables => undef,
    admin => undef,
);

sub item {
    my ($self) = @_;
    my $cs = $self->config_store;
    my @auth;
    my @cluster;
    my @host_configs;
    my %item = (
        auths => \@auth,
        cluster => \@cluster,
        host_configs => \@host_configs,
    );

    for my $id ($cs->_Sections()) {
        if (exists $fields{$id}) {
            my $d = $cs->read($id);
            if ($id eq 'iptables') {
                for my $f (qw(clients cluster_ips)) {
                    $d->{$f} = [split /\s*,\s*/, $d->{$f}];
                }
            }
            $item{$id} = $d;
            next;
        }

        if ($id =~ /^auth (.*)$/) {
            my $user = $1;
            my $d = $cs->read($id);
            $d->{user} = $user;
            push @auth, $d;
            next;
        }

        if ($id eq 'cluster') {
            my $d = $cs->read($id);
            while (my ($k,$v) = each %$d) {
                push @cluster, { name => $k, value => $v};
            }
            next;
        }

        my @host_config;
        my $d = $cs->read($id);
        while (my ($k,$v) = each %$d) {
            push @host_config, { name => $k, value => $v};
        }

        @host_configs = { config => \@host_config, host => $id };
    }
    @host_configs = sort { $a->{host} <=> $b->{host} } @host_configs;
    return \%item;
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
