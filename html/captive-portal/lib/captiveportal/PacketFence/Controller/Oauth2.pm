package captiveportal::PacketFence::Controller::Oauth2;
use Moose;
use namespace::autoclean;
use pf::config;
use pf::util qw(isenabled);
use pf::web;
use Net::OAuth2::Client;
use pf::auth_log;

BEGIN { extends 'captiveportal::Base::Controller'; }

=head1 NAME

captiveportal::PacketFence::Controller::Oauth2 - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.



=head1 METHODS

=cut

our %VALID_OAUTH_PROVIDERS = (
    google   => undef,
    facebook => undef,
    github   => undef,
    windowslive => undef,
    linkedin => undef,
    twitter => undef,
);

=head2 auth_provider

/oauth2/auth/:provider

=cut

sub auth_provider : Local('auth'): Args(1) {
    my ( $self, $c, $provider ) = @_;
    pf::auth_log::record_oauth_attempt($provider, $c->portalSession->clientMac);
    $c->response->redirect($self->oauth2_client($c,$provider)->authorize);
}

=head2 auth

/oauth2/auth

=cut

sub auth : Local: Args(0) {
    my ( $self, $c ) = @_;
    my $provider = $c->request->query_params->{'provider'};
    $c->forward('auth_provider',[$provider]);
}

=head2 index

/oauth2/auth

=cut

sub index :Path : Args(0) {
    my ( $self, $c ) = @_;
    my $provider = $c->request->query_params->{'request'};
    $c->forward('oauth2Result',[$provider]);
}

=head2 oauth2_client

=cut

sub oauth2_client {
    my ($self,$c,$provider) = @_;
    my $logger = $c->log;
    my $portalSession = $c->portalSession;
    my $type;
    my $token_scheme = "auth-header:OAuth";
    if (lc($provider) eq 'facebook') {
        $type = pf::Authentication::Source::FacebookSource->meta->get_attribute('type')->default;
    } elsif (lc($provider) eq 'github') {
        $type = pf::Authentication::Source::GithubSource->meta->get_attribute('type')->default;
        $token_scheme = "uri-query:access_token";
    } elsif (lc($provider) eq 'google') {
        $type = pf::Authentication::Source::GoogleSource->meta->get_attribute('type')->default;
    } elsif (lc($provider) eq 'linkedin'){
        $type = pf::Authentication::Source::LinkedInSource->meta->get_attribute('type')->default;
        $token_scheme = "uri-query:oauth2_access_token";
    } elsif (lc($provider) eq 'windowslive'){
        $type = pf::Authentication::Source::WindowsLiveSource->meta->get_attribute('type')->default;
        $token_scheme = "auth-header:Bearer";
    } elsif (lc($provider) eq 'twitter'){
        $type = pf::Authentication::Source::TwitterSource->meta->get_attribute('type')->default;
    }

    if ($type) {
        my $source = $portalSession->profile->getSourceByType($type);
        if ($source) {
            # Twitter source is special, we need our homemade lib
            # that's included in the source
            if ($type eq 'Twitter'){
                return $source;
            }

            return Net::OAuth2::Profile::WebServer->new(
                client_id => $source->{'client_id'},
                client_secret => $source->{'client_secret'},
                site => $source->{'site'},
                authorize_path => $source->{'authorize_path'},
                access_token_path => $source->{'access_token_path'},
                access_token_method => $source->{'access_token_method'},
                #access_token_param => $source->{'access_token_param'},
                scope => $source->{'scope'},
                redirect_uri => $source->{'redirect_url'},
                token_scheme => $token_scheme, 
          );
        }
        else {
            $logger->error(sprintf("No source of type '%s' defined for profile '%s'", $type, $portalSession->profile->getName));
        }
    }
    $self->showError($c,"OAuth2 Error: Error loading provider");
}

=head2 oauth2Result

/oauth2/:provider

Handles the oauth request coming from the providers

=cut

sub oauth2Result : Path : Args(1) {
    my ($self, $c, $provider) = @_;
    my $logger        = $c->log;
    my $portalSession = $c->portalSession;
    my $session       = $c->session;
    my $profile       = $portalSession->profile;
    my $request       = $c->request;
    my %info;
    my $pid;

    # Pull username
    $info{'pid'} = "default";

    # Pull browser user-agent string
    $info{'user_agent'} = $request->user_agent;

    my $code = $request->query_params->{'code'};

    $logger->debug("API CODE: $code");

    #Get the token
    my $token;

    eval {
        if ($provider eq 'twitter') {
            my $oauth_token = $request->query_params->{oauth_token};
            my $oauth_verifier = $request->query_params->{oauth_verifier}; 
            $logger->info("Got token $oauth_token and verifier $oauth_verifier to finish authorization with Twitter");
            $token = $self->oauth2_client($c, $provider)->get_access_token($oauth_token, $oauth_verifier);
        }
        else{
            $token = $self->oauth2_client($c,$provider)->get_access_token($code);
        }
    };

    if ($@) {
        $logger->warn(
            "OAuth2: failed to receive the token from the provider: $@");
        $c->stash->{txt_auth_error} = i18n("OAuth2 Error: Failed to get the token");
        pf::auth_log::change_record_status($provider, $c->portalSession->clientMac, $pf::auth_log::FAILED);
        $c->detach(Authenticate => 'showLogin');
    }

    my $response;

    my $type;

    $provider = lc($provider);
    # Validate the token
    if ($provider eq 'facebook') {
        $type =
          pf::Authentication::Source::FacebookSource->meta->get_attribute(
            'type')->default;
    } elsif ($provider eq 'github') {
        $type = pf::Authentication::Source::GithubSource->meta->get_attribute(
            'type')->default;
    } elsif ($provider eq 'google') {
        $type = pf::Authentication::Source::GoogleSource->meta->get_attribute(
            'type')->default;
    } elsif ($provider eq 'linkedin') {
        $type = pf::Authentication::Source::LinkedInSource->meta->get_attribute(
            'type')->default;
    } elsif ($provider eq 'windowslive') {
        $type = pf::Authentication::Source::WindowsLiveSource->meta->get_attribute(
            'type')->default;
    } elsif ($provider eq 'twitter') {
        $type = pf::Authentication::Source::TwitterSource->meta->get_attribute(
            'type')->default;
    }
    
    my $source = $profile->getSourceByType($type);
    if ($source) { 
        # in twitter, the username comes with the access token through our homemade lib
        if ($provider eq 'twitter') {
            $pid = $token->{username}.'@twitter';
        }
        else {
            # request a JSON response
            my $h = HTTP::Headers->new( 'x-li-format' => 'json' );
            $response = $token->get($source->{'protected_resource_url'}, $h ); 
            if ($response->is_success) {
                if ($provider eq 'linkedin'){
                    # response is sent as "email@example.com" with quotes
                    $pid = $response->content() ;
                    # remove the quotes
                    $pid =~ s/"//g;
                    $source->lookup_from_provider_info($pid, {email => $pid});
                }
                else{
                    # Grab JSON content
                    my $json      = new JSON;
                    my $json_text = $json->decode($response->content());
                    if ($provider eq 'windowslive'){
                        $pid = $json_text->{emails}->{account};
                    } elsif ($provider eq 'github') {
                        # The user can decide to not display his e-mail. In that case we use the username and suffix @github
                        $pid = $json_text->{email} || $json_text->{login}.'@github';
                    } else {
                        $pid = $json_text->{email};
                    }
                    $logger->info("OAuth2 successfull, register and release for username $pid");
                    $source->lookup_from_provider_info($pid, $json_text);
                }         
            } else {
                $logger->info(
                    "OAuth2: failed to validate the token, redireting to login page"
                );
                pf::auth_log::change_record_status($provider, $c->portalSession->clientMac, $pf::auth_log::FAILED);
                $c->stash->{txt_auth_error} = i18n("OAuth2 Error: Failed to validate the token, please retry");
                $c->detach(Authenticate => 'showLogin');
            }
        }

        pf::auth_log::record_completed_oauth($provider, $c->portalSession->clientMac, $pid, $pf::auth_log::COMPLETED);
        $c->session->{"username"} = $pid;
        $c->session->{source_id} = $source->{id};
        $c->session->{source_match} = undef;
        $c->stash->{info}=\%info; 
        my $auth_params = { 'username' => $pid, 'user_email' => $pid };
        $c->forward('Authenticate' => 'postAuthentication');
        $c->forward('Authenticate' => 'createLocalAccount', [$auth_params]) if ( isenabled($source->{create_local_account}) );
        $c->forward('CaptivePortal' => 'webNodeRegister', [$pid, %{$c->stash->{info}}]);
        $c->forward('CaptivePortal' => 'endPortalSession');

    } else {
        $logger->error(
            sprintf(
                "No source of type '%s' defined for profile '%s'",
                $type, $profile->getName
            )
        );
        $c->response->redirect( $c->portalSession->destinationUrl );
    }
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
