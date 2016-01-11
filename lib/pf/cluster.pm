package pf::cluster;

=head1 NAME

pf::cluster

=cut

=head1 DESCRIPTION

Interface to get information about the cluster based on the cluster.conf

=cut

use strict;
use warnings;

use pf::log;
use Sys::Hostname;
use pfconfig::cached_hash;
use pfconfig::cached_array;
use pfconfig::cached_scalar;
use List::MoreUtils qw(first_index);
use Net::Interface;
use NetAddr::IP;
use Socket;
use pf::file_paths;
use pf::util;
use pf::constants;

use Exporter;
our ( @ISA, @EXPORT );
@ISA = qw(Exporter);
@EXPORT = qw(%ConfigCluster @cluster_servers @cluster_hosts $cluster_enabled $host_id $CLUSTER);

our ($cluster_enabled, %ConfigCluster, @cluster_servers, @cluster_hosts);
tie %ConfigCluster, 'pfconfig::cached_hash', 'config::Cluster';
tie @cluster_servers, 'pfconfig::cached_array', 'resource::cluster_servers';
tie @cluster_hosts, 'pfconfig::cached_array', 'resource::cluster_hosts';
$cluster_enabled = sub {
    my $cfg = Config::IniFiles->new( -file => $cluster_config_file );
    return 0 unless($cfg);
    my $mgmt_ip = $cfg->val('CLUSTER', 'management_ip');
    defined($mgmt_ip) && valid_ip($mgmt_ip) ? 1 : 0 ;
}->();

our $CLUSTER = "CLUSTER";

our $host_id = hostname();

=head2 is_management

Returns 1 if this node is the management node (i.e. owning the management ip)

=cut

sub is_management {
    my $logger = get_logger();
    unless($cluster_enabled){
        $logger->info("Clustering is not enabled. Cannot be management node.");
        return 0;
    }
    my $cluster_ip = management_cluster_ip();
    my @all_ifs = Net::Interface->interfaces();
    foreach my $inf (@all_ifs) {
        my @masks = $inf->netmask(AF_INET());
        my @addresses = $inf->address(AF_INET());
        for my $i (0 .. $#masks) {
            if (inet_ntoa($addresses[$i]) eq $cluster_ip) {
                return 1;
            }
        }
    }
    return 0;

}

=head2 get_host_id

Returns the current host id (hostname)

=cut

sub get_host_id {
    return $host_id;
}

=head2 current_server

Returns the cluster config for this server

=cut

sub current_server {
    return $cluster_servers[cluster_index()];
}

=head2 cluster_ip

Returns the cluster IP address for an interface

=cut

sub cluster_ip {
    my ($interface) = @_;
    return $ConfigCluster{$CLUSTER}->{"interface $interface"}->{ip};
}

=head2 management_cluster_ip

Returns the management cluster IP address for the cluster

=cut

sub management_cluster_ip {
    return $ConfigCluster{$CLUSTER}->{management_ip};
}

=head2 cluster_index

Returns the index of this server in the cluster (lower is better)

=cut

sub cluster_index {
    my $cluster_index = first_index { $_ eq $host_id } @cluster_hosts;
    return $cluster_index;
}

=head2 is_dhcpd_primary

Compute whether or not this node is the primary DHCP server in the cluster

=cut

sub is_dhcpd_primary {
    if(scalar(@cluster_servers) > 1){
        # the non-management node is the primary
        return cluster_index() == 1 ? 1 : 0;
    }
    else {
        # the server is alone so it's the primary
        return 1;
    }
}

=head2 should_offer_dhcp

Get whether or not this node should offer DHCP

=cut

sub should_offer_dhcp {
    cluster_index() <= 1 ? 1 : 0;
}

=head2 dhcpd_peer

Get the IP address of the DHCP peer for an interface

=cut

sub dhcpd_peer {
    my ($interface) = @_;

    unless(defined($cluster_servers[1])){
        return undef;
    }

    if(cluster_index() == 0){
        return $cluster_servers[1]{"interface $interface"}->{ip};
    }
    else {
        return $cluster_servers[0]{"interface $interface"}->{ip};
    }
}

=head2 mysql_servers

Get the list of the MySQL servers ordered by priority

=cut

sub mysql_servers {
    if(scalar(@cluster_servers) >= 1){
        # we make the prefered management node the last prefered for MySQL
        my @servers = @cluster_servers;
        my $management = shift @servers;
        push @servers, $management;
        return @servers;
    }
    else{
        return @cluster_servers;
    }
}

=head2 members_ips

Get all the members IP for an interface

=cut

sub members_ips {
    my ($interface) = @_;
    my $logger = get_logger();
    unless(exists($ConfigCluster{$host_id}->{"interface $interface"}->{ip})){
        $logger->warn("requesting member ips for an undefined interface...");
        return {};
    }
    my %data = map { $_->{host} => $_->{"interface $interface"}->{ip} } @cluster_servers;
    return \%data;
}

=head2 api_call_each_server

Call an API method on each member of the cluster

=cut

sub api_call_each_server {
    my ($asynchronous, $api_method, %api_args) = @_;
    
    require pf::api::jsonrpcclient;
    my @failed;
    foreach my $server (@cluster_servers){
        next if($server->{host} eq $host_id);
        my $apiclient = pf::api::jsonrpcclient->new(host => $server->{management_ip}, proto => 'https');
        eval {
            pf::log::get_logger->info("Calling $api_method on $server->{host}");
            my $result;
            unless($asynchronous){
                ($result) = $apiclient->call($api_method, %api_args );
            }
            else {
                ($result) = $apiclient->notify($api_method, %api_args );
            }
        };
        if($@){
            pf::log::get_logger->error("Failed to call $api_method . $@");
            push @failed, $server->{host};
        }
    }
    return \@failed;
}

=head2 sync_files

Sync files through all members of a cluster

=cut

sub sync_files {
    my ($files, %options) = @_;
    unless($cluster_enabled){
        get_logger->trace("Won't sync files because we're not in a cluster");
        return [];
    }

    my @failed;
    foreach my $file (@$files){
        my %data = ( conf_file => $file, from => pf::cluster::current_server()->{management_ip} );
        push @failed, @{api_call_each_server($options{async}, 'distant_download_configfile', %data)};
    }
    return \@failed;
}

=head2 send_dir_copy

Send a message to the other cluster servers to copy a directory from their filesystem

=cut

sub send_dir_copy {
    my ($source_dir, $dest_dir, %options) = @_;
    return api_call_each_server($options{async}, 'copy_directory', $source_dir, $dest_dir);
}

=head2 sync_storages

Sync a storage through all members of a cluster

=cut

sub sync_storages {
    my ($stores, %options) = @_;
    require pf::api::jsonrpcclient;
    my $apiclient = pf::api::jsonrpcclient->new();
    foreach my $store (@$stores){
        eval {
            print "Synching storage : $store\n";
            my $cs = $store->new;
            my $pfconfig_namespace = $cs->pfconfigNamespace;
            my $config_file = $cs->configFile;
            my %data = (
                namespace => $pfconfig_namespace,
                conf_file => $config_file,
            );
            my ($result) = $apiclient->call( 'expire_cluster', %data );
        };
        if($@){
            print STDERR "ERROR !!! Failed to sync store : $store ($@) \n";
        }
    }
}

=head2 is_vip_running

=cut

sub is_vip_running {
    my ($int) = @_;

    if ( defined($ConfigCluster{$CLUSTER}->{"interface $int"}) ) {

        my @all_ifs = Net::Interface->interfaces();
        foreach my $inf (@all_ifs) {
            if ($inf->name eq $int) {
                my @masks = $inf->netmask(AF_INET());
                my @addresses = $inf->address(AF_INET());
                for my $i (0 .. $#masks) {
                    if (inet_ntoa($addresses[$i]) eq cluster_ip($int)) {
                        return $TRUE;
                    }
                }
                return $FALSE;
            }
        }
    }
    return $FALSE;
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2016 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and::or
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
