package captiveportal::Controller::Authenticate;

use Moose;
use namespace::autoclean;
use pf::config;
use pf::log;
use pf::web qw(i18n);
use pf::node;
use pf::util;
use pf::locationlog;
use pf::authentication;
use HTML::Entities;
use List::MoreUtils qw(any);

BEGIN { extends 'captiveportal::Base::Controller'; }

=head1 NAME

captiveportal::Controller::Authenticate - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

__PACKAGE__->config(
    {   action_args => {
            index => {
                valid_modes => {
                    aup        => 'aup',
                    status     => 'status',
                    release    => 'release',
                    next_page  => 'next_page',
                    deregister => 'deregister',
                }
            }
        }
    }
);

=head1 METHODS

=head2 begin

=cut

sub begin {
    my ( $self, $c ) = @_;
    $c->forward(Root => 'validateMac');
}

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    my $mode   = $c->request->param('mode');
    my $action = $c->action;
    if ( defined $mode ) {
        my $path = $self->modeToPath( $c, $mode );
        $c->go($path);
    } else {
        $c->detach('login');
    }
}

sub modeToPath {
    my ( $self, $c, $mode ) = @_;
    my $action = $c->action;
    my $path   = 'default';
    if ( exists $action->{valid_modes}{$mode} ) {
        $path = $action->{valid_modes}{$mode};

    } elsif (
        exists $c->config->{'captiveportal::Custom'}{Authenticate}{modes}
        {$mode}
        && defined $c->config->{'captiveportal::Custom'}
        ->{Authenticate}{modes}{$mode} ) {
        $path = $c->config->{'captiveportal::Custom'}
          ->{Authenticate}{modes}{$mode};
    }
    return $path;
}

sub next_page : Local : Args(0) {
    my ( $self, $c ) = @_;
    my $pagenumber = $c->request->param('page');

    $pagenumber = 1 if ( !defined($pagenumber) );

    if (   ( $pagenumber >= 1 )
        && ( $pagenumber <= $Config{'registration'}{'nbregpages'} ) ) {

        $c->stash( reg_page_content_file => "register_$pagenumber.html", );

        # generate list of locales
        my $authorized_locale_txt = $Config{'general'}{'locale'};
        my @authorized_locale_array = split( /,/, $authorized_locale_txt );
        my @locales;
        if ( scalar(@authorized_locale_array) == 1 ) {
            push @locales,
              { name => 'locale', value => $authorized_locale_array[0] };
        } else {
            foreach my $authorized_locale (@authorized_locale_array) {
                push @locales,
                  { name => 'locale', value => $authorized_locale };
            }
        }
        $c->stash->{'list_locales'} = \@locales;

        if ( $pagenumber == $Config{'registration'}{'nbregpages'} ) {
            $c->stash->{'button_text'} =
              $Config{'registration'}{'button_text'};
            $c->stash->{'form_action'} = '/authenticate';
        } else {
            $c->stash->{'button_text'} = "Next page";
            $c->stash->{'form_action'} =
              '/authenticate?mode=next_page&page=' . ( int($pagenumber) + 1 );
        }

        $c->stash->{template} = 'register.html';
    } else {
        $self->showError( $c, "error: invalid page number" );
    }
}

sub deregister : Local : Args(0) {
    my ( $self, $c ) = @_;
    if ( $self->authenticateUser($c) ) {
        my $portalSession = $c->portalSession;
        my $mac           = $portalSession->clientMac;
        my $node_info     = node_view($mac);
        my $pid           = $node_info->{'pid'};
        if ( $c->session->{username} eq $pid ) {
            pf::node::node_deregister($mac);
        } else {
            $self->showError( $c, "error: access denied not owner" );
        }
    } else {
        $c->forward('login');
    }
}

sub authenticateUser {
    my ( $self, $portalSession ) = @_;
}

sub aup : Local : Args(0) {
    my ( $self, $c ) = @_;
    $c->detach( 'Aup', 'index' );
}

sub status : Local : Args(0) {
    my ( $self, $c ) = @_;
    $c->detach( 'Status', 'index' );
}

sub default : Path {
    my ( $self, $c, $mode ) = @_;
    my $path = $self->modeToPath( $c, $mode );
    if ( $path eq 'default' ) {
        $self->showError( $c, "error: incorrect mode" );
    } else {
        $c->go($path);
    }
}

sub login : Local : Args(0) : Hookable {
    my ( $self, $c ) = @_;
    if ( $c->request->method eq 'POST' ) {

        # External authentication
        $c->forward('validateLogin');
        $c->forward('authenticationLogin');
        $c->forward('postAuthentication');
        $c->forward( 'Root' => 'webNodeRegister', [$c->session->{username}, %{$c->stash->{info}}] );
        $c->forward( 'Root' => 'endPortalSession' );
    }

    # Return login
    $c->forward('showLogin');

}

=head2 postAuthentication

TODO: documention

=cut

sub postAuthentication : Hookable('Private') {
    my ( $self, $c ) = @_;
    my $logger = get_logger;
    $c->detach('showLogin') if $c->stash->{txt_auth_error};
    my $portalSession = $c->portalSession;
    my $session = $c->session;
    my $info = $c->stash->{info} || {};
    my $source_id = $session->{source_id};
    my $pid = $session->{"username"};
#    $pid = $default_pid if $no_username_needed;
    my $params = { username => $pid };
    my $mac = $portalSession->clientMac;

    # TODO : add current_time and computer_name
    my $locationlog_entry = locationlog_view_open_mac($mac);
    if ($locationlog_entry) {
        $params->{connection_type} = $locationlog_entry->{'connection_type'};
        $params->{SSID}            = $locationlog_entry->{'ssid'};
    }

    # obtain node information provided by authentication module. We need to get the role (category here)
    # as web_node_register() might not work if we've reached the limit
    my $value =
      &pf::authentication::match( $source_id, $params, $Actions::SET_ROLE );

    $logger->trace("Got role '$value' for username $pid");

    # This appends the hashes to one another. values returned by authenticator wins on key collision
    if ( defined $value ) {
        $info->{category} = $value;
    }

    # If an access duration is defined, use it to compute the unregistration date;
    # otherwise, use the unregdate when defined.
    $value =
      &pf::authentication::match( $source_id, $params,
        $Actions::SET_ACCESS_DURATION );
    if ( defined $value ) {
        $value = POSIX::strftime( "%Y-%m-%d %H:%M:%S",
            localtime( time + normalize_time($value) ) );
        $logger->trace("Computed unrege date from access duration: $value");
    } else {
        $value =
          &pf::authentication::match( $source_id, $params,
            $Actions::SET_UNREG_DATE );
    }
    if ( defined $value ) {
        $logger->trace("Got unregdate $value for username $pid");
        $info->{unregdate} = $value;
    }
    $c->stash->{info} = $info;
}

sub validateLogin : Hookable('Private') {
    my ( $self, $c ) = @_;
    my $logger  = get_logger;
    my $profile = $c->profile;
    $logger->debug("form validation attempt");

    my $request = $c->request;
    my $no_password_needed =
      any { $_ eq 'null' } @{ $profile->getGuestModes };
    my $no_username_needed = _no_username($profile);

    if (   ( $request->param("username") || $no_username_needed )
        && ( $request->param("password") || $no_password_needed ) ) {

        # acceptable use pocliy accepted?
        my $aup_signed = $request->param("aup_signed");
        if (   !defined($aup_signed)
            || !$aup_signed ) {
            $c->stash->{txt_auth_error} =
              'You need to accept the terms before proceeding any further.';
            $c->detach('showLogin');
        }
    } else {
        $c->detach('showLogin');
    }
}

sub authenticationLogin : Hookable('Private') {
    my ( $self, $c ) = @_;
    my $logger  = get_logger;
    my $session = $c->session;
    my $request = $c->request;
    my $profile = $c->profile;
    $logger->trace("authentication attempt");

    my @sources =
      ( $profile->getInternalSources, $profile->getExclusiveSources );
    my $username = $request->param("username");
    my $password = $request->param("password");

    # validate login and password
    my ( $return, $message, $source_id ) =
      pf::authentication::authenticate( $username, $password, @sources );

    if ( defined($return) && $return == 1 ) {

        # save login into session
        $c->session->{"username"} = $request->param("username");
        $c->session->{source_id} = $source_id;
    } else {
        $c->stash( txt_auth_error => i18n($message) );
    }
}

sub _no_username {
    my ($profile) = @_;
    return any { $_->type eq 'Null' && isdisabled( $_->email_required ) }
    $profile->getSourcesAsObjects;
}

sub showLogin : Hookable('Private') {
    my ( $self, $c ) = @_;
    my $profile    = $c->profile;
    my $guestModes = $profile->getGuestModes;
    my $guest_allowed =
      any { is_in_list( $_, $guestModes ) } $SELFREG_MODE_EMAIL,
      $SELFREG_MODE_SMS, $SELFREG_MODE_SPONSOR;
    my $request = $c->request;
    $c->stash(
        template        => 'login.html',
        username        => encode_entities( $request->param("username") ),
        null_source     => is_in_list( $SELFREG_MODE_NULL, $guestModes ),
        oauth2_github   => is_in_list( $SELFREG_MODE_GITHUB, $guestModes ),
        oauth2_google   => is_in_list( $SELFREG_MODE_GOOGLE, $guestModes ),
        no_username     => _no_username($profile),
        oauth2_facebook => is_in_list( $SELFREG_MODE_FACEBOOK, $guestModes ),
        guest_allowed   => 1,
    );
}

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
