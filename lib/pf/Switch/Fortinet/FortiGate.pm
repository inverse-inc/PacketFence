package pf::Switch::Fortinet::FortiGate;

=head1 NAME

pf::Switch::Fortinet::FortiGate - Object oriented module to FortiGate using the external captive portal

=head1 SYNOPSIS

The pf::Switch::Fortinet::FortiGate  module implements an object oriented interface to interact with the FortiGate captive portal

=head1 STATUS

=cut

=head1 BUGS AND LIMITATIONS

No doing deauthentication since this is a web form released switch

=cut

use strict;
use warnings;
use pf::node;
use pf::violation;
use pf::locationlog;
use pf::util;
use LWP::UserAgent;
use HTTP::Request::Common;
use pf::log;
use pf::constants;

use base ('pf::Switch::Fortinet');

=head1 METHODS

=cut

sub description { 'FortiGate Firewall with web auth' }

sub supportsExternalPortal { return $TRUE; }
sub supportsWebFormRegistration { return $TRUE }
sub supportsWirelessMacAuth { return $TRUE; }
sub supportsWiredMacAuth { return $TRUE; }


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
        switch_id               => $req->param('apip'),
        client_mac              => clean_mac($req->param('usermac')),
        client_ip               => $req->param('userip'),
        grant_url               => $req->param('post'),
        status_code             => '200',
        synchronize_locationlog => $TRUE,
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
        my $violation = pf::violation::violation_view_top($args->{'mac'});
        # if user is unregistered or is in violation then we reject him to show him the captive portal
        if ( $node->{status} eq $pf::node::STATUS_UNREGISTERED || defined($violation) ){
            $logger->info("[$args->{'mac'}] is unregistered. Refusing access to force the eCWP");
            my $radius_reply_ref = {
                'Tunnel-Medium-Type' => $RADIUS::ETHERNET,
                'Tunnel-Type' => $RADIUS::VLAN,
                'Tunnel-Private-Group-ID' => -1,
            };
            ($radius_reply_ref, $status) = $filter->handleAnswerInRule($rule,$args,$radius_reply_ref);
            return [$status, %$radius_reply_ref];

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
        <form name="weblogin_form" method="POST" action="$post">
            <input type="hidden" name="username" value="$mac">
            <input type="hidden" name="password" value="$mac">
            <input type="hidden" name="magic" value="$magic">
            <input type="submit" style="display:none;">
        </form>
        <script language="JavaScript" type="text/javascript">
        window.setTimeout('document.weblogin_form.submit();', 1000);
        </script>
    ];

    $logger->debug("Generated the following html form : ".$html_form);
    return $html_form;
}

=head2 deauthenticateMacDefault

Just log since there is no way to deauthenticate

=cut

sub deauthenticateMacDefault {
    get_logger->info("No doing deauthentication since this is a web form released switch.");
}

=head2 getVersion

return a constant since there is no api for this

=cut

sub getVersion {
    my ($self) = @_;
    return 0;
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

1;
