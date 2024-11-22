#!/usr/bin/perl

=head1 NAME

Iplogs

=cut

=head1 DESCRIPTION

unit test for Iplogs

=cut

use strict;
use warnings;

BEGIN {
    #include test libs
    use lib qw(/usr/local/pf/t);
    #Module for overriding configuration paths
    use setup_test_config;
}

use DateTime;
use DateTime::Format::Strptime;
use pf::ip4log;
use pf::dal::ip4log;
use pf::dal::ip4log_history;
use pf::dal::ip4log_archive;

use Test::More tests => 34;
use Test::Mojo;
use Test::NoWarnings;
my $t = Test::Mojo->new('pf::UnifiedApi');

#pre-cleanup
pf::dal::ip4log->remove_items();
pf::dal::ip4log_history->remove_items();
pf::dal::ip4log_archive->remove_items();

#run unittest on empty dB
$t->get_ok('/api/v1/ip4logs' => json => { })
  ->json_is('/items',[])
  ->status_is(200);
  
#setup data
my $ip = '0.0.0.1';
my $mac = '00:01:02:03:04:05';
my $escaped_mac = '00%3A01%3A02%3A03%3A04%3A05';
my $lease_length = 120;
my $dt_format = DateTime::Format::Strptime->new(pattern => '%Y-%m-%d %H:%M:%S');
my $dt_start = DateTime->now(time_zone=>'local');
my $dt_end = DateTime->now(time_zone=>'local')->add(seconds => $lease_length);
  
#insert good data
my $status = pf::ip4log::open($ip, $mac, $lease_length);

#run unittest on single dB entry
$t->get_ok('/api/v1/ip4logs')
  ->status_is(200)
  ->json_is('/items/0/mac',$mac)
  ->json_is('/items/0/ip',$ip)
  ->json_has('/items/0/start_time')
  ->json_has('/items/0/end_time')
;
#run unittest on list by mac
$t->get_ok('/api/v1/ip4logs/open/'.$mac)
  ->status_is(200)
  ->json_is('/item/ip',$ip)
  ->json_is('/item/mac',$mac)
  ->json_has('/item/start_time')
  ->json_has('/item/end_time')
;
#run unittest on list by mac
$t->get_ok('/api/v1/ip4logs/open/'.$escaped_mac)
  ->status_is(200)
  ->json_is('/item/ip',$ip)
  ->json_is('/item/mac',$mac)
  ->json_has('/item/start_time')
  ->json_has('/item/end_time')
;
  
#run unittest on history list by mac
$t->get_ok('/api/v1/ip4logs/history/'.$mac => json => { })
  ->status_is(200)
  ->json_is('/items/0/ip',$ip)
  ->json_is('/items/0/mac',$mac)
  ->json_has('/items/0/start_time')
  ->json_has('/items/0/end_time')
;
  
#run unittest on archive list by mac
$t->get_ok('/api/v1/ip4logs/archive/'.$mac => json => { })
  ->json_is('/items/0/ip',$ip)
  ->json_is('/items/0/mac',$mac)
  ->json_has('/items/0/start_time')
  ->json_has('/items/0/end_time')
  ->status_is(200)
;
  
#debug output
#my $j = $t->tx->res->json;
#use Data::Dumper;print Dumper($j);

#post-cleanup
pf::dal::ip4log->remove_items();
pf::dal::ip4log_history->remove_items();
pf::dal::ip4log_archive->remove_items();
  
  
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
