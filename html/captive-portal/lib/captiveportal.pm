package captiveportal;
use Moose;
use namespace::autoclean;
use Log::Log4perl::Catalyst;

use Catalyst::Runtime 5.80;
use POSIX qw(setlocale);
use Locale::gettext qw(bindtextdomain textdomain);

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
  -Debug
  ConfigLoader
  Static::Simple
  I18N
  Authentication
  Session
  Session::Store::CHI
  Session::State::Cookie
  StackTrace
  /;

use Try::Tiny;

use constant INSTALL_DIR => '/usr/local/pf';
use lib INSTALL_DIR . "/lib";

BEGIN {
    use pf::log service => 'httpd.portal';
}

use pf::config::cached;
use pf::file_paths;
use pf::CHI;

extends 'Catalyst';

our $VERSION = '0.01';
bindtextdomain( "packetfence", "$conf_dir/locale" );
textdomain("packetfence");

# Configure the application.
#
# Note that settings in captive_portal.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name         => 'captiveportal',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    'static'                                    => {
        mime_types => { woff => 'font/woff' },

        # Include static content from captive portal in order to render previews of
        # remediation pages (see pfappserver::Controller::Violation)
        include_path => [
            \&loadCustomStatic,
            INSTALL_DIR . '/html/captive-portal',
            INSTALL_DIR . '/html/common',
            INSTALL_DIR . '/html',
        ],
        ignore_dirs => [
            qw(
              pfappserver templates
              t profile-templates lib script
              )
        ],
        ignore_extensions => [qw/cgi php inc tt html xml pl pm/],
    },
    'Plugin::Session'          => {
        chi_class => 'pf::CHI',
        chi_args => {
            namespace => 'httpd.portal',
        },
        cookie_name => 'CGISESSION',
    },
    default_view               => 'HTML',
);

before handle_request => sub {
    pf::config::cached::ReloadConfigs();
};

sub loadCustomStatic {
    my ($c)           = @_;
    my $dirs          = [];
    my $portalSession = $c->portalSession;
    if ($portalSession) {
        $dirs = $portalSession->templateIncludePath;
    }
    return $dirs;
}

sub user_cache {
    return pf::CHI->new( namespace => 'httpd.portal');
}

has portalSession => (
    is => 'rw',
    lazy => 1,
    builder => '_build_portalSession',
);

sub _build_portalSession {
    my ($c) = @_;
    return $c->model('Portal::Session');
}

has profile => (
    is => 'rw',
    lazy => 1,
    builder => '_build_profile',
);

sub _build_profile {
    my ($c) = @_;
    return $c->portalSession->profile;
}

after finalize => sub {
    my ($c) = @_;
    if ( ref($c) ) {
        my $deferred_actions = delete $c->stash->{_deferred_actions} || [];
        foreach my $action (@$deferred_actions) {
            eval { $action->(); };
            if ($@) {
                $c->log->error("Error with a deferred action: $@");
            }
        }
    }
};

sub add_deferred_actions {
    my ( $c, @args ) = @_;
    if ( ref($c) ) {
        my $deferred_actions = $c->stash->{_deferred_actions} ||= [];
        push @$deferred_actions, @args;
    }
}

sub has_errors {
    my ($c) = @_;
    return scalar @{$c->error};
}

__PACKAGE__->log(Log::Log4perl::Catalyst->new(INSTALL_DIR . '/conf/log.conf.d/httpd.portal.conf',watch_delay => 5 * 60));

# Handle warnings from Perl as error log messages
$SIG{__WARN__} = sub { __PACKAGE__->log->error(@_); };

# Start the application
__PACKAGE__->setup();

=head1 NAME

captiveportal - Catalyst based application

=head1 SYNOPSIS

    script/captive_portal_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<captiveportal::Controller::Root>, L<Catalyst>

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
