package captiveportal::Controller::Root;
use Moose;
use namespace::autoclean;
use pf::web::constants;
use URI::Escape qw(uri_escape uri_unescape);
use HTML::Entities;
use pf::enforcement qw(reevaluate_access);
use pf::config;
use pf::log;
use pf::util;
use pf::Portal::Session;
use Apache2::Const -compile => qw(OK DECLINED HTTP_MOVED_TEMPORARILY);
use pf::web;
use pf::node;
use pf::useragent;
use pf::violation;
use pf::class;
use Cache::FileCache;
use pf::sms_activation;

BEGIN { extends 'captiveportal::Base::Controller'; }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config( namespace => '' );

our $USERAGENT_CACHE =
  new Cache::FileCache( { 'namespace' => 'CaptivePortal_UserAgents' } );

our $LOST_DEVICES_CACHE =
  new Cache::FileCache( { 'namespace' => 'CaptivePortal_LostDevices' } );

=head1 NAME

captiveportal::Controller::Root - Root Controller for captiveportal

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS


=head2 auto

=cut

sub auto : Hookable('Private') {
    my ( $self, $c ) = @_;
    $c->forward('setupCommonStash');
    return 1;
}

=head2 checkForViolation

TODO: documention

=cut

sub checkForViolation : Hookable('Private') {
    my ( $self, $c ) = @_;
    my $portalSession = $c->portalSession;
    my $mac           = $portalSession->clientMac;
    my $logger        = $c->log;
    my $violation = violation_view_top($mac);
    if ($violation) {

        $c->stash->{'user_agent'} = $c->request->user_agent;
        my $request = $c->req;

        # There is a violation, redirect the user
        # FIXME: there is not enough validation below
        my $vid      = $violation->{'vid'};
        my $SCAN_VID = 12003;

        # detect if a system scan is in progress, if so redirect to scan in progress page
        if (   $vid == $SCAN_VID
            && $violation->{'ticket_ref'}
            =~ /^Scan in progress, started at: (.*)$/ ) {
            $logger->info(
                "captive portal redirect to the scan in progress page");
            $c->detach( 'scan_status', [$1] );
        }
        my $class    = class_view($vid);
        my $template = $class->{'template'};
        $logger->info(
            "captive portal redirect on violation vid: $vid, redirect template: $template"
        );

        # The little redirect dance here is controlled by frames which are inherently alterable by the user
        # TODO: We need to validate that a user cannot request a frame with the enable button activated

        # enable button
        if ( $request->param("enable_menu") ) {
            $logger->debug(
                "violation redirect: generating enable button frame (enable_menu = 1)"
            );
            $c->detach( 'Enabler', 'index' );
        } elsif ( $class->{'auto_enable'} eq 'Y' ) {
            $logger->debug(
                "violation redirect: showing violation remediation page inside a frame"
            );
            $c->detach( 'Redirect', 'index' );
        }
        $logger->debug(
            "violation redirect: showing violation remediation page directly since there is no enable button"
        );

        # Retrieve violation template name

        my $subTemplate = $self->getSubTemplate( $c, $class->{'template'} );
        $logger->info("Showing the $subTemplate  remediation page.");
        my $node_info = node_view($mac);
        $c->stash(
            'template'     => 'remediation.html',
            'sub_template' => $subTemplate,
            map { $_ => $node_info->{$_} }
              qw(dhcp_fingerprint last_switch last_port
              last_vlan last_connection_type last_ssid username)
        );
        $c->detach;
    }
}

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    $c->forward('validateMac');
    $c->forward('nodeRecordUserAgent');
    $c->forward('supportsMobileconfigProvisioning');
    $c->response->redirect('captive-portal');
}

=head2 nodeRecordUserAgent

TODO: documention

=cut

sub nodeRecordUserAgent : Hookable('Private') {
    my ( $self, $c ) = @_;
    my $user_agent    = $c->request->user_agent;
    my $logger        = get_logger;
    my $portalSession = $c->portalSession;
    my $mac           = $portalSession->clientMac;

    # caching useragents, if it's the same don't bother triggering violations
    my $cached_useragent = $USERAGENT_CACHE->get($mac);

    # Cache hit
    return
      if ( defined($cached_useragent) && $user_agent eq $cached_useragent );

    # Caching and updating node's info
    $logger->trace("adding $mac user-agent to cache");
    $USERAGENT_CACHE->set( $mac, $user_agent, "5 minutes" );

    # Recording useragent
    $logger->info(
        "Updating node $mac user_agent with useragent: '$user_agent'");
    node_modify( $mac, ( 'user_agent' => $user_agent ) );

    # updates the node_useragent information and fires relevant violations triggers
    return pf::useragent::process_useragent( $mac, $user_agent );
}

=head2 supportsMobileconfigProvisioning

TODO: documention

=cut

sub supportsMobileconfigProvisioning : Hookable('Private') {
    my ( $self, $c ) = @_;
    my $do_not_deauth = $FALSE;
    if ( isenabled( $Config{'provisioning'}{'autoconfig'} ) ) {

        # is this an iDevice?
        # TODO get rid of hardcoded targets like that
        my $node_attributes = node_attributes( $c->portalSession->clientMac );
        my @fingerprint =
          dhcp_fingerprint_view( $node_attributes->{'dhcp_fingerprint'} );
        unless ( !defined( $fingerprint[0]->{'os'} )
            || $fingerprint[0]->{'os'} !~ /Apple iPod, iPhone or iPad/ ) {

            # do we perform provisioning for this category?
            my $config_category = $Config{'provisioning'}{'category'};
            my $node_cat        = $node_attributes->{'category'};

            # validating that the node is under the proper category for mobile config provioning
            $do_not_deauth = $TRUE
              if ( $config_category eq 'any'
                || ( defined($node_cat) && $node_cat eq $config_category ) );
        }
    }

    # otherwise
    $c->session->{"do_not_deauth"} = $do_not_deauth;
}

=head2 setupCommonStash

TODO: documention

=cut

sub setupCommonStash : Hookable('Private') {
    my ( $self, $c ) = @_;
    my $portalSession   = $c->portalSession;
    my $destination_url = $c->request->param('destination_url');
    if ( defined $destination_url ) {
        $destination_url = decode_entities( uri_unescape($destination_url) );
    } else {
        $destination_url = $Config{'trapping'}{'redirecturl'};
    }
    my @list_help_info;
    push @list_help_info,
      { name => i18n('IP'), value => $portalSession->clientIp }
      if ( defined( $portalSession->clientIp ) );
    push @list_help_info,
      { name => i18n('MAC'), value => $portalSession->clientMac }
      if ( defined( $portalSession->clientMac ) );
    $c->stash(
        pf::web::constants::to_hash(),
        destination_url => $destination_url,
        logo            => $c->profile->getLogo,
        list_help_info  => \@list_help_info,
    );
}

=head2 validateMac

TODO: documention

=cut

sub validateMac : Hookable('Private') {
    my ( $self, $c ) = @_;
    my $portalSession = $c->portalSession;
    my $mac           = $portalSession->clientMac;
    $c->log->info("mac : $mac");
    if ( !valid_mac($mac) ) {
        $self->showError( $c, "error: not found in the database" );
        $c->detach;
    }
}

sub endPortalSession : Hookable('Private') {
    my ( $self, $c ) = @_;
    my $logger        = get_logger;
    my $portalSession = $c->portalSession;

    # First blast at handling portalSession object
    my $mac             = $portalSession->clientMac();
    my $destination_url = $c->stash->{destination_url};

    # violation handling
    my $count = violation_count($mac);
    if ( $count != 0 ) {
        print $c->response->redirect( '/captive-portal?destination_url='
              . uri_escape($destination_url) );
        $logger->info("more violations yet to come for $mac");
    }

    # handle mobile provisioning if relevant
    $c->forward('mobileconfig_provisioning');

    # we drop HTTPS so we can perform our Internet detection and avoid all sort of certificate errors
    if ( $c->request->secure ) {
        $c->response->redirect( "http://"
              . $Config{'general'}{'hostname'} . "."
              . $Config{'general'}{'domain'}
              . '/access?destination_url='
              . uri_escape($destination_url) );
    }

    $c->forward( 'Release' => 'index' );
}

sub mobileconfig_provisioning : Hookable('Private') {
    my ( $self, $c ) = @_;
    my $logger = Log::Log4perl::get_logger('pf::web');

    return if ( isdisabled( $Config{'provisioning'}{'autoconfig'} ) );
    my $portalSession = $c->portalSession;

    # First blast at handling portalSession object
    my $mac = $portalSession->clientMac();

    # is this an iDevice?
    # TODO get rid of hardcoded targets like that
    my $node_attributes = node_attributes($mac);
    my @fingerprint =
      dhcp_fingerprint_view( $node_attributes->{'dhcp_fingerprint'} );
    return
      if ( !defined( $fingerprint[0]->{'os'} )
        || $fingerprint[0]->{'os'} !~ /Apple iPod, iPhone or iPad/ );

    # do we perform provisioning for this category?
    my $config_category = $Config{'provisioning'}{'category'};
    my $node_cat        = $node_attributes->{'category'};

    # validating that the node is under the proper category for mobile config provioning
    if ( $config_category eq 'any'
        || ( defined($node_cat) && $node_cat eq $config_category ) ) {
        $c->stash( template => 'release_with_xmlconfig.html' );
        $c->detach;
    }
}

sub checkIfPending : Hookable('Private') {
    my ( $self, $c ) = @_;
    my $portalSession = $c->portalSession;
    my $profile       = $c->profile;
    my $mac           = $portalSession->clientMac;
    my $node_info     = node_view($mac);
    my $request       = $c->request;
    if ( defined($node_info)
        && $node_info->{'status'} eq $pf::node::STATUS_PENDING ) {
        if ( pf::sms_activation::sms_activation_has_entry($mac) ) {
            node_deregister($mac);
            $c->stash(
                template => 'guest/sms_confirmation.html',
                post_uri => '/activate/sms'
            );
        } elsif ( $request->secure ) {

            # we drop HTTPS for pending so we can perform our Internet detection and avoid all sort of certificate errors
            print $c->response->redirect( "http://"
                  . $Config{'general'}{'hostname'} . "."
                  . $Config{'general'}{'domain'}
                  . '/captive-portal?destination_url='
                  . uri_escape( $portalSession->getDestinationUrl ) );
        } else {
            $c->stash(
                template => 'pending.html',
                retry_delay =>
                  $CAPTIVE_PORTAL{'NET_DETECT_PENDING_RETRY_DELAY'},
                external_ip =>
                  $Config{'captive_portal'}{'network_detection_ip'},
                redirect_url => $Config{'trapping'}{'redirecturl'},
                initial_delay =>
                  $CAPTIVE_PORTAL{'NET_DETECT_PENDING_INITIAL_DELAY'},
            );

            # override destination_url if we enabled the always_use_redirecturl option
            if ( isenabled( $Config{'trapping'}{'always_use_redirecturl'} ) )
            {
                $c->stash->{'destination_url'} =
                  $Config{'trapping'}{'redirecturl'};
            }

        }
        $c->detach;
    }
}

=head2 proxy_redirect

Mod_proxy redirect

=cut

sub proxy_redirect {
    my ( $r, $url ) = @_;
    my $logger = get_logger;
    $r->set_handlers( PerlResponseHandler => [] );
    $r->filename( "proxy:" . $url );
    $r->proxyreq(2);
    $r->handler('proxy-server');
    return Apache2::Const::OK;
}

sub getSubTemplate {
    my ( $self, $c, $template ) = @_;
    my $portalSession = $c->portalSession;
    return "violations/$template.html";
#    my $langs         = $portalSession->getRequestLanguages();
    my $langs         = [];
    my $paths         = $portalSession->templateIncludePath();
    my @subTemplates =
      map { "violations/$template" . ( $_ ? ".$_" : "" ) . ".html" } @$langs,
      '';
    return first { -f $_ } map {
        my $path = $_;
        map {"$path/$_"} @subTemplates
    } @$paths;
}

=head2 webNodeRegister

This sub is meant to be redefined by pf::web::custom to fit your specific needs.
See F<pf::web::custom> for examples.

=cut

sub webNodeRegister : Hookable('Private') {
    my ($self, $c, $pid, %info ) = @_;
    my $logger        = Log::Log4perl::get_logger(__PACKAGE__);
    my $portalSession = $c->portalSession;

    # FIXME quick and hackish fix for #1505. A proper, more intrusive, API changing, fix should hit devel.
    my $mac;
    if ( defined( $portalSession->guestNodeMac ) ) {
        $mac = $portalSession->guestNodeMac;
    } else {
        $mac = $portalSession->clientMac;
    }

    if ( is_max_reg_nodes_reached( $mac, $pid, $info{'category'} ) ) {
        $c->forward('maxRegNodesReached');
        $c->detach;
    }
    node_register( $mac, $pid, %info );

    unless ( defined($c->session->{"do_not_deauth"}) && $c->session->{"do_not_deauth"} == $TRUE ) {
        reevaluate_access( $mac, 'manage_register' );
    }

    # we are good, push the registration
}



=head2 maxRegNodesReached

TODO: documention

=cut

sub maxRegNodesReached : Hookable('Private') {
    my ( $self, $c ) = @_;
    $self->showError($c, "You have reached the maximum number of devices you are able to register with this username.");
}



sub web_user_authenticate : Hookable('Private') {
    my ( $self, $c ) = @_;
    my $profile = $c->profile;
    my $request = $c->request;
    my $logger = get_logger;
    $logger->trace("authentication attempt");

    my @sources = ($profile->getInternalSources, $profile->getExclusiveSources);
    my $username = $request->param("username");
    my $password = $request->param("password");

    # validate login and password
    my ($return, $message, $source_id) = pf::authentication::authenticate($username, $password, @sources);

    if (defined($return) && $return == 1) {
        # save login into session
        $c->session->{"username"} = $username;
    }
    return ($return, $message, $source_id);
}


=head2 default

Standard 404 error page

=cut

sub default : Path : Hookable {
    my ( $self, $c ) = @_;
    $c->response->body('Page not found');
    $c->response->status(404);
}

sub error : Private { }

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') { }

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
