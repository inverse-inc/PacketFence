package pf::pfcron::task::password_of_the_day;

=head1 NAME

pf::pfcron::task::password_of_the_day - class for pfcron task password generation

=cut

=head1 DESCRIPTION

pf::pfcron::task::password_of_the_day

=cut

use strict;
use warnings;
use Moose;
use pf::person;
use pf::password;
use pf::authentication;
use pf::util;
use pf::web qw (i18n_format );
use pf::web::guest;
use DateTime;
use DateTime::Format::MySQL;
use pf::log;
use pf::I18N;
use DateTime::TimeZone;
pf::I18N::setup_text_domain();

extends qw(pf::pfcron::task);

=head2 run

run the password generation task

=cut

sub run {
    my ( $self ) = @_;
    my $tz = $ENV{TZ} || DateTime::TimeZone->new( name => 'local' )->name();
    my $now = DateTime->now(time_zone => $tz);
    my $logger = get_logger();
    my $sources = pf::authentication::getAuthenticationSourcesByType("Potd");
    my $new_password;
    foreach my $source (@{$sources}) {
        unless (person_exist($source->{id})) {
            $logger->info("Create Person $source->{id}");
            my $return = person_add($source->{id}, (potd => 'yes'));
            if ($return == 2 ) {
                next;
            }
            $new_password = pf::password::generate($source->{id},[{type => 'valid_from', value => $now},{type => 'expiration', value => pf::config::access_duration($source->{password_rotation})}],undef,'0',$source);
            $self->send_email(pid => $source->{id}, password => $new_password, email => $source->{password_email_update}, expiration => pf::config::access_duration($source->{password_rotation}));
            next;
        }
        my $password = pf::password::view($source->{id});
        if(defined($password)){
            my $expiration = $password->{expiration};
            $expiration = DateTime::Format::MySQL->parse_datetime($expiration);
            $expiration->set_time_zone($tz);
            if ( $now->epoch > $expiration->epoch) {
                $new_password = pf::password::generate($source->{id},[{type => 'valid_from', value => $now},{type => 'expiration', value => pf::config::access_duration($source->{password_rotation})}],undef,'0',$source);
                $self->send_email(pid => $source->{id},password => $new_password, email => $source->{password_email_update}, expiration => pf::config::access_duration($source->{password_rotation}));
            }
        }
    }
}

=head2 send_email

send the password of the day to the email addresses

=cut

sub send_email {
    my ( $self, %info ) = @_;
    %info = (
        'subject'   => i18n_format("New password of the day"),
        %info
    );
    pf::web::guest::send_template_email(
            $pf::web::guest::TEMPLATE_EMAIL_PASSWORD_OF_THE_DAY, $info{'subject'}, \%info
    );

}

=head1 AUTHOR


Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2023 Inverse inc.

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
