package captiveportal::PacketFence::DynamicRouting::Module::Authentication::Login;

=head1 NAME

captiveportal::DynamicRouting::Module::Authentication::Login

=head1 DESCRIPTION

Login registration

=cut

use Moose;
extends 'captiveportal::DynamicRouting::Module::Authentication';
with 'captiveportal::Role::FieldValidation';
with 'captiveportal::Role::MultiSource';

use pf::util;
use pf::log;
use pf::config::util;
use List::MoreUtils qw(all);
use pf::auth_log;
use pf::person;
use pf::Authentication::constants;
use pf::web::guest;
use pf::node qw(node_view);

has '+pid_field' => (default => sub { "username" });

has '+sources' => (isa => 'ArrayRef['.join('|', @{sources_classes()}).']');

has '+multi_source_object_classes' => (default => sub{sources_classes()});

sub sources_classes {
    return [ 
        "pf::Authentication::Source::SQLSource",
        "pf::Authentication::Source::LDAPSource",
        "pf::Authentication::Source::HtpasswdSource",
        "pf::Authentication::Source::KerberosSource",
        "pf::Authentication::Source::EAPTLSSource",
        "pf::Authentication::Source::HTTPSource",
        "pf::Authentication::Source::RADIUSSource",
    ];
}

=head2 required_fields_child

Username and password are required for login

=cut

sub required_fields_child {
    return ["username", "password"];
}

=head2 execute_child

Execute this module

=cut

sub execute_child {
    my ($self) = @_;
    if($self->app->request->method eq "POST"){
        $self->authenticate();
    }
    else {
        $self->prompt_fields();
    }
};

=head2 authenticate

Authenticate the POSTed username and password

=cut

sub authenticate {
    my ($self) = @_;
    my $username = $self->request_fields->{$self->pid_field};
    my $password = $self->request_fields->{password};
    
    my ($stripped_username, $realm) = strip_username($username);

    my @sources = get_user_sources($self->sources, $stripped_username, $realm);
    get_logger->info("Authenticating user using sources : ", join(',', (map {$_->id} @sources)));

    unless(@sources){
        get_logger->info("No sources found for $username");
        $self->app->flash->{error} = "No authentication source found for this username";
        $self->prompt_fields();
        return;
    }

    # If all sources use the stripped username, we strip it
    # Otherwise, we leave it as is
    my $use_stripped = all { isenabled($_->{stripped_user_name}) } @sources;
    if($use_stripped){
        $username = $stripped_username;
    }

    if ($self->app->reached_retry_limit("login_retries", $self->app->profile->{'_login_attempt_limit'})) {
        $self->app->flash->{error} = $GUEST::ERRORS{$GUEST::ERROR_MAX_RETRIES};
        $self->prompt_fields();
        return;
    }

    if(isenabled($self->app->profile->reuseDot1xCredentials)) {
        my $mac       = $self->current_mac;
        my $node_info = node_view($mac);
        ($username,$realm) = strip_username($node_info->{'last_dot1x_username'});
        get_logger->info("Reusing 802.1x credentials. Gave username ; $username");
        my $params = {
            username => $node_info->{'last_dot1x_username'},
            connection_type => $node_info->{'last_connection_type'},
            SSID => $node_info->{'last_ssid'},
            stripped_user_name => $username,
            rule_class => 'authentication',
        };
        # Test the source to find the matching source
        my $source_id;
        my $role = &pf::authentication::match([@sources], $params, $Actions::SET_ROLE, \$source_id);
        if ( defined($role) ) {
            $self->source(pf::authentication::getAuthenticationSource($source_id));
            #Update username
            $self->username($username);
        } else {
            get_logger->error("Reusing 802.1x credentials but not able to find the source for username $username");
            $self->app->flash->{error} = "Reusing 802.1x credentials but not able to find the source for username $username, did you define the source on the portal ?";
        }
    } else {
        # validate login and password
        my ( $return, $message, $source_id ) =
          pf::authentication::authenticate( { 'username' => $username, 'password' => $password, 'rule_class' => $Rules::AUTH }, @sources );
        if ( defined($return) && $return == 1 ) {
            $self->source(pf::authentication::getAuthenticationSource($source_id));

            if($self->source->type eq "SQL"){
                unless(pf::password::consume_login($username)){
                    $self->app->flash->{error} = "Account has used all of its available logins";
                    $self->prompt_fields();
                    return;
                }
            }

            pf::auth_log::record_auth($source_id, $self->current_mac, $username, $pf::auth_log::COMPLETED);
            # Logging USER/IP/MAC of the just-authenticated user
            get_logger->info("Successfully authenticated ".$username);
        } else {
            pf::auth_log::record_auth(join(',',map { $_->id } @sources), $self->current_mac, $username, $pf::auth_log::FAILED);
            $self->app->flash->{error} = $message;
            $self->prompt_fields();
            return;
        }
    }
    
    $self->update_person_from_fields();
    $self->username($username);
    $self->done();
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2016 Inverse inc.

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

__PACKAGE__->meta->make_immutable;

1;

