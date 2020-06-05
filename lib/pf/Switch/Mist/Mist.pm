package pf::Switch::Mist::Mist;

=head1 NAME

pf::Switch::Mist::Mist - Object oriented module to Mist using the external captive portal

=head1 SYNOPSIS

The pf::Switch::Mist::Mist  module implements an object oriented interface to interact with the Mist captive portal

=head1 STATUS

Initial version

=cut

=head1 BUGS AND LIMITATIONS

Not doing deauthentication in web auth

=cut

use strict;
use warnings;
use pf::node;
use pf::security_event;
use pf::locationlog;
use pf::util;
use LWP::UserAgent;
use HTTP::Request::Common;
use pf::log;
use pf::constants;
use pf::accounting qw(node_accounting_dynauth_attr);
use pf::config qw ($WEBAUTH_WIRELESS);
use pf::constants::role qw($REJECT_ROLE);

use base ('pf::Switch::Mist');

=head1 METHODS

=cut

sub description { 'Mist with external portal' }

sub supportsExternalPortal { return $TRUE; }
sub supportsWebFormRegistration { return $TRUE }
sub supportsWirelessMacAuth { return $TRUE; }
sub supportsWiredMacAuth { return $TRUE; }
sub supportsWirelessDot1x { return $TRUE; }
sub supportsVPN { return $TRUE; }

=item getIfIndexByNasPortId

Return constant sice there is no ifindex

=cut

sub getIfIndexByNasPortId {
   return 'external';
}


=item parseExternalPortalRequest

Parse external portal request using URI and it's parameters then return an hash reference with the appropriate parameters
See L<pf::web::externalportal::handle>

=cut

sub parseExternalPortalRequest {
    my ( $self, $r, $req ) = @_;
    my $logger = $self->logger;

    # Using a hash to contain external portal parameters
    my %params = ();

    %params = (
        #switch_id               => $req->param('ap_mac'),
        #client_mac              => clean_mac($req->param('client_mac')),
        client_mac               => $req->param('client_mac'),
        #client_ip               => $req->param('userip'),
        #grant_url               => $req->param('post'),
        status_code             => '200',
        synchronize_locationlog => $TRUE,
        connection_type         => $WEBAUTH_WIRELESS,
    );

    return \%params;
}

=head2 returnRadiusAccessAccept

Prepares the RADIUS Access-Accept reponse for the network device.

Overriding the default implementation for the external captive portal

=cut

sub returnRadiusAccessAccept {
    my ($self, $args) = @_;
    my $logger = $self->logger;


    my $radius_reply_ref = {};
    my $status;
    # should this node be kicked out?
    my $kick = $self->handleRadiusDeny($args);
    return $kick if (defined($kick));

    my $node = $args->{'node_info'};
    my $filter = pf::access_filter::radius->new;
    my $rule = $filter->test('returnRadiusAccessAccept', $args);

    if ( $self->externalPortalEnforcement ) {
        my $security_event = pf::security_event::security_event_view_top($args->{'mac'});
        # if user is unregistered or is in security_event then we reject him to show him the captive portal
        if ( $node->{status} eq $pf::node::STATUS_UNREGISTERED || defined($security_event) ){
            $logger->info("[$args->{'mac'}] is unregistered. Refusing access to force the eCWP");
            $args->{user_role} = $REJECT_ROLE;
            $self->handleRadiusDeny();
        }
        else{
            $logger->info("Returning ACCEPT");
            ($radius_reply_ref, $status) = $filter->handleAnswerInRule($rule,$args,$radius_reply_ref);
            return [$status, %$radius_reply_ref];
        }
    }

    return $self->SUPER::returnRadiusAccessAccept($args);
}

=head2 getAcceptForm

Return the accept form to the client

=cut

sub getAcceptForm {
    my ( $self, $mac , $destination_url,$cgi_session) = @_;
    my $logger = $self->logger;
    $logger->debug("Creating web release form");


    my $magic = $cgi_session->param("ecwp-original-param-magic");
    my $post = $cgi_session->param("ecwp-original-param-post");

    my $html_form = qq[
        <form name="weblogin_form" data-autosubmit="1000" method="POST" action="$post">
            <input type="hidden" name="username" value="$mac">
            <input type="hidden" name="password" value="$mac">
            <input type="hidden" name="magic" value="$magic">
            <input type="submit" style="display:none;">
        </form>
        <script src="/content/autosubmit.js" type="text/javascript"></script>
    ];

    $logger->debug("Generated the following html form : ".$html_form);
    return $html_form;
}

=item deauthenticateMacDefault

Overrides base method to send Acct-Session-Id within the RADIUS disconnect request

=cut

sub deauthenticateMacDefault {
    my ( $self, $mac, $is_dot1x ) = @_;
    my $logger = $self->logger;

    if ( !$self->isProductionMode() ) {
        $logger->info("not in production mode... we won't perform deauthentication");
        return 1;
    }

    #Fetching the acct-session-id
    my $dynauth = node_accounting_dynauth_attr($mac);

    $logger->debug("deauthenticate $mac using RADIUS Disconnect-Request deauth method");
    return $self->radiusDisconnect(
        $mac, { 'Acct-Session-Id' => $dynauth->{'acctsessionid'}, 'User-Name' => $dynauth->{'username'} },
    );
}

=head2 getVersion

return a constant since there is no api for this

=cut

sub getVersion {
    my ($self) = @_;
    return 0;
}

=item identifyConnectionType

Determine Connection Type based on radius attributes

=cut


sub identifyConnectionType {
    my ( $self, $connection, $radius_request ) = @_;
    my $logger = $self->logger;

    my @require = qw(Fortinet-Vdom-Name);
    my @found = grep {exists $radius_request->{$_}} @require;

    if (@require == @found) {
        $connection->isVPN($TRUE);
        $connection->isCLI($FALSE);
    } else {
        $connection->isVPN($FALSE);
    }
}


=item returnAuthorizeVPN

Return radius attributes to allow VPN access

=cut

sub returnRadiusAuthorizeVPN {
    my ($self, $args) = @_;
    my $logger = $self->logger;


    my $radius_reply_ref = {};
    my $status;
    # should this node be kicked out?
    my $kick = $self->handleRadiusDeny($args);
    return $kick if (defined($kick));

    my $node = $args->{'node_info'};
    my $filter = pf::access_filter::radius->new;
    my $rule = $filter->test('returnRadiusAccessAccept', $args);
    $logger->info("Returning ACCEPT");
    ($radius_reply_ref, $status) = $filter->handleAnswerInRule($rule,$args,$radius_reply_ref);
    return [$status, %$radius_reply_ref];
}

=item parseVPNRequest

Redefinition of pf::Switch::parseVPNRequest due to specific attribute being used

=cut

sub parseVPNRequest {
    my ( $self, $radius_request ) = @_;
    my $logger = $self->logger;

    my $client_ip       = ref($radius_request->{'Calling-Station-Id'}) eq 'ARRAY'
                           ? clean_ip($radius_request->{'Calling-Station-Id'}[0])
                           : clean_ip($radius_request->{'Calling-Station-Id'});

    my $user_name       = $self->parseRequestUsername($radius_request);
    my $nas_port_type   = $radius_request->{'NAS-Port-Type'};
    my $port            = $radius_request->{'NAS-Port'};
    my $eap_type        = ( exists($radius_request->{'EAP-Type'}) ? $radius_request->{'EAP-Type'} : 0 );
    my $nas_port_id     = ( defined($radius_request->{'NAS-Port-Id'}) ? $radius_request->{'NAS-Port-Id'} : undef );

    return ($nas_port_type, $eap_type, undef, $port, $user_name, $nas_port_id, undef, $nas_port_id);
}


=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2019 Inverse inc.

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
