package pf::role::pool;

=head1 NAME

pf::role::pool - Object oriented module for VLAN pool

=head1 SYNOPSIS

The pf::role::pool module contains the functions necessary for the VLAN Pool.

=cut

use strict;
use warnings;

use Log::Log4perl;

use pf::config qw(%Config);
use pf::util;
use pf::log();
use pf::constants::role qw(:all);
use pf::error qw(is_error is_success);

use pf::node;
use pf::dal;

use Number::Range;

=head1 SUBROUTINES

Warning: The list of subroutine is incomplete

=cut

=head2 new

Constructor.

=cut

sub new {
    my $logger =  pf::log::get_logger();
    $logger->debug("instantiating new pf::role::pool object");
    my ( $class, %argv ) = @_;
    my $this = bless {}, $class;
    return $this;
}

sub getVlanFromPool {
    my ($self, $args) = @_;
    my $logger =  pf::log::get_logger();

    return unless(defined($args->{vlan}));

    return $args->{'vlan'} if $self->rangeValidator($args->{'vlan'});
    my $range = Number::Range->new($args->{'vlan'});
    my $vlan;
    if ($args->{'profile'}->{'_vlan_pool_technique'} eq $POOL_USERNAMEHASH ) {
        $logger->trace("Use $POOL_USERNAMEHASH algorithm for VLAN pool");
        $vlan = $self->getVlanByUsername($args, $range);
    } elsif ($args->{'profile'}->{'_vlan_pool_technique'} eq $POOL_RANDOM) {
        $logger->trace("Use $POOL_RANDOM algorithm for VLAN pool");
        $vlan = $self->getRandomVlanInPool($args, $range);
    } elsif ($args->{'profile'}->{'_vlan_pool_technique'} eq $POOL_PER_USER_VLAN) {
        $logger->trace("Use $POOL_PER_USER_VLAN algorithm for VLAN pool");
        $vlan = $self->getPerUserVlan($args, $range);
    } else {
        $logger->trace("Use round robin algorithm for VLAN pool");
        $vlan = $self->getRoundRobin($args, $range);
    }
    return $vlan;
}

=head2 rangeValidator

Validate the range definition
Should be something like that 20..23 or 20..23,27..30

=cut

sub rangeValidator {
    my ($self, $range) =@_;
    my $rangesep = qr/(?:\.\.)/;
    my $sectsep  = qr/(?:\s|,)/;
    my $validation = qr/(?:
         [^0-9,. -]|
         $rangesep$sectsep|
         $sectsep$rangesep|
         \d-\d|
         ^$sectsep|
         ^$rangesep|
         $sectsep$|
         $rangesep$
         )/x;
    return 1 if ($range =~ m/$validation/g);
    return 1 if ($range =~ m/^\d+$/g);
    return 0;
}

=head2 getRandomVlanInPool

Get a random VLAN in the pool to assign to the node unless its previous VLAN is part of the pool

=cut

sub getRandomVlanInPool {
    my ($self, $args, $range) = @_;
    my $logger =  pf::log::get_logger();

    my $vlan_count = $range->size;
    my $node_info_complete = node_view($args->{'mac'});
    if ( defined($node_info_complete->{'last_vlan'}) && $range->inrange($node_info_complete->{'last_vlan'}) ) {
        $logger->debug("Using the last VLAN that was assigned to the node: ".$node_info_complete->{'last_vlan'});
        return ($node_info_complete->{'last_vlan'});
    }

    $logger->debug("Computing a random VLAN in the pool for the node since its last VLAN was not in the pool");

    my @array = $range->range;
    return $array[int(rand($vlan_count))];
}


=head2 getRoundRobin

Return the vlan id based on the last registered device + 1
First test if the last_vlan of the device is in the range then use it
Else get the last registered device vlan and add + 1 (+1 in the range)

=cut

sub getRoundRobin {
    my ($self, $args, $range) = @_;
    my $logger =  pf::log::get_logger();

    my $vlan_count = $range->size;
    my $node_info_complete = node_view($args->{'mac'});
    if ( defined($node_info_complete->{'last_vlan'}) && $range->inrange($node_info_complete->{'last_vlan'}) ) {
        $logger->debug("Using the last VLAN that was assigned to the node: ".$node_info_complete->{'last_vlan'});
        return ($node_info_complete->{'last_vlan'});
    }
    my $last_reg_node = node_last_reg_non_inline_on_category($args->{'mac'}, $args->{'user_role'});
    my $last_reg_mac = $last_reg_node->{mac};
    my @array = $range->range;

    if (defined($last_reg_mac) && $last_reg_mac ne '') {
        $logger->debug("Last registered node in role $args->{'user_role'} is $last_reg_mac");
        my $new_vlan;
        my $last_reg_mac_info = node_view($last_reg_mac);
        $logger->debug("Last VLAN assigned to registered device: ".$last_reg_mac_info->{'last_vlan'});
        if (defined($last_reg_mac_info->{'last_vlan'})) {
            my ( $index )= grep { $array[$_] =~ /^$last_reg_mac_info->{'last_vlan'}$/ } 0..$#array;
            if( 0 <= $index && $index <= $vlan_count) {
                $new_vlan = ($index + 1) % $vlan_count;
            } else {
               $new_vlan = 0;
            }
        } else {
            $new_vlan = 0;
        }
        $logger->trace("Return VLAN ID: ".$array[$new_vlan]);
        return ($array[$new_vlan]);
    } else {
        $logger->info("First device in the VLAN pool, returned VLAN ID: ".$array[0]);
        return ($array[0]);
    }
}


=head2 getVlanByUsername

Return the vlan id based on a hash of the username

=cut

sub getVlanByUsername {
    my ( $self, $args, $range ) = @_;
    my $logger = pf::log::get_logger();
    my $index = unpack( "%16C*", $args->{'node_info'}->{'pid'} ) + length($args->{'node_info'}->{'pid'});

    my $vlan_count = $range->size;
    my @array = $range->range;
    my $new_vlan = ($index + 1) % $vlan_count;
    $logger->trace("Return VLAN ID: ".$array[$new_vlan]);
    return ($array[$new_vlan]);

}

sub getPerUserVlan {
    my ($self, $args, $range) = @_;
    my $logger = pf::log::get_logger();

    my $pid = $args->{node_info}->{pid};
    my @vlans = $range->range;
    my $sql_vlans = join(",", map { pf::dal->get_dbh->quote($_) } @vlans);

    my ($status, $res) = pf::dal->db_execute("
    SELECT vlan 
    FROM   locationlog 
           JOIN node USING (mac)
    WHERE  vlan IN ( $sql_vlans ) 
           AND node.status = 'reg' 
           AND pid = ? 
    LIMIT 1
    ", $pid);

    if(is_error($status)) {
        $logger->error("Error while finding available VLAN for $pid");
        return;
    }

    if(defined(my $row = $res->fetchrow_hashref)) {
        my $vlan = $row->{vlan};
        $logger->info("Found VLAN $vlan for $pid with registered devices in it.");
        $res->finish();
        return $vlan;
    }
    else {
        $logger->debug("Unable to find a VLAN in the pool that $pid has devices in. Finding an available VLAN for this user.");
        ($status, $res) = pf::dal->db_execute("
        SELECT vlan 
        FROM   locationlog 
               JOIN node USING (mac)
        WHERE  vlan IN ( $sql_vlans ) 
               AND node.status != 'unreg' 
        ");
        if(is_error($status)) {
            $logger->error("Error while finding available VLAN for $pid");
            return;
        }

        my %used_vlans = map{$_->[0] => 1} @{$res->fetchall_arrayref};
        $res->finish();
        my $available_vlan;
        for my $vlan (@vlans) {
            if(!exists($used_vlans{$vlan})) {
                $available_vlan = $vlan;
                last;
            }
        }
        if($available_vlan) {
            $logger->info("Found available VLAN $available_vlan in the pool for $pid");
            return $available_vlan;
        }
        else {
            $logger->error("No available VLAN in the pool");
            return;
        }
    }
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

# vim: set shiftwidth=4:
# vim: set expandtab:
# vim: set backspace=indent,eol,start:
