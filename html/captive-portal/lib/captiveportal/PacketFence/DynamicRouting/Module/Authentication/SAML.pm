package captiveportal::PacketFence::DynamicRouting::Module::Authentication::SAML;

=head1 NAME

captiveportal::DynamicRouting::Module::Authentication::SAML

=head1 DESCRIPTION

SAML authentication

=cut

use Moose;
extends 'captiveportal::DynamicRouting::Module::Authentication';
with 'captiveportal::Role::Routed';

use LWP::UserAgent;
use URI;
use pf::util;
use pf::auth_log;
use pf::log;
use JSON::MaybeXS;

has '+source' => (isa => 'pf::Authentication::Source::SAMLSource');

has '+route_map' => (default => sub {
    tie my %map, 'Tie::IxHash', (
        '/saml/redirect' => \&redirect,
        '/saml/assertion' => \&assertion,
        # fallback to the index
        '/captive-portal' => \&index,
    );
    return \%map;
});

=head2 execute_child

Execute the module

=cut

sub execute_child {
    my ($self) = @_;
    $self->index();
}

=head2 index

SAML index

=cut

sub index {
    my ($self) = @_;
    $self->render("saml.html", {source => $self->source, title => "SAML authentication"});
}

=head2 redirect

Redirect the user to the SAML IDP

=cut

sub redirect {
    my ($self) = @_;
    pf::auth_log::record_oauth_attempt($self->source->id, $self->current_mac);

    my $ua = LWP::UserAgent->new();
    my $url = URI->new("http://localhost:9091/sso_url.cgi");
    $url->query_form(source_id => $self->source->id);
    my $res = $ua->get($url);
    if($res->is_success) {
        $self->app->redirect($res->decoded_content);
    }
    else {
        get_logger->error("Unable to communicate will SAML CGI interface : ".$res->status_line);
        $self->app->error("An error has occured. Please contact your local support staff.");
    }
}

=head2 assertion

Handle the assertion that comes back from the IDP

=cut

sub assertion {
    my ($self) = @_;

    my $ua = LWP::UserAgent->new();
    my $url = URI->new("http://localhost:9091/assertion.cgi");
    my $res = $ua->post($url, {source_id => $self->source->id, SAMLResponse => $self->app->request->param("SAMLResponse")});
    if($res->is_success) {
        my $return = decode_json($res->decoded_content);
        my $username = $return->{username};
        my $msg = $return->{msg};
        # We strip the username if the authorization source requires it.
        if(isenabled($self->source->authorization_source->{stripped_user_name})){
            ($username, undef) = strip_username($username);
        }

        if($username){
            pf::auth_log::record_completed_oauth($self->source->id, $self->current_mac, $username, $pf::auth_log::COMPLETED);
            $self->username($username);
            $self->done();
        }
        else {
            $self->app->error($msg);
            pf::auth_log::change_record_status($self->source->id, $self->current_mac, $pf::auth_log::FAILED);
        }
    }
    else {
        get_logger->error("Unable to communicate will SAML CGI interface : ".$res->status_line);
        $self->app->error("An error has occured. Please contact your local support staff.");
    }

}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2017 Inverse inc.

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

