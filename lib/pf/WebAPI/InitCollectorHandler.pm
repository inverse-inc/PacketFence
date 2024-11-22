package pf::WebAPI::InitCollectorHandler;

=head1 NAME

pf::WebAPI::InitCollectorHandler

=cut

=head1 DESCRIPTION

pf::WebAPI::InitCollectorHandler

=cut

use strict;
use warnings;

use Apache2::RequestRec ();
use pf::log;
use pf::Redis;
use JSON::MaybeXS;
use pf::AtFork;
use Apache2::Const -compile => 'OK';

sub handler {
    my $r = shift;
    return Apache2::Const::OK;
}

=head2 child_init

Initialize the child process
Reestablish connections to global connections
Refresh any configurations

=cut

sub child_init {
    my ($class, $child_pool, $s) = @_;
    my $redis = pf::Redis->new(server => '127.0.0.1:6379');
    #Avoid child processes having the same random seed
    srand();
    pf::AtFork::run_child_child_callbacks();
    return Apache2::Const::OK;
}

=head2 post_config

Cleaning before forking child processes
Close connections to avoid any sharing of sockets

=cut

sub post_config {
    my ($class, $conf_pool, $log_pool, $temp_pool, $s) = @_;
    return Apache2::Const::OK;
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>


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

1;

