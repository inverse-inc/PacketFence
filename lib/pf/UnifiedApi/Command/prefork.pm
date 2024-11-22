package pf::UnifiedApi::Command::prefork;

=head1 NAME

pf::UnifiedApi::Command::prefork - Pre-fork command

=cut

use Linux::Systemd::Daemon 'sd_ready';
use Mojo::Base qw(Mojolicious::Command::prefork);
use pf::config qw(%Config);

sd_ready;

sub run {
  my ($self, @args) = @_;
  Linux::Systemd::Daemon::sd_notify( READY => 1, STATUS => "Ready", unset => 1 );
  my $timeout = $Config{advanced}{pfperl_api_timeout} // 600;
  eval {
    $self->SUPER::run('-i', $timeout, '-H', $timeout, '-w', $Config{advanced}{pfperl_api_processes}, @args);
  };
  if ($@) {
      print STDERR $@;
  }
  Linux::Systemd::Daemon::sd_notify( STOPPING => 1 );
}

1;

=back

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

Minor parts of this file may have been contributed. See CREDITS.

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
