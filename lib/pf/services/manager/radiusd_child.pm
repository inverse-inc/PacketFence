package pf::services::manager::radiusd_child;

=head1 NAME

pf::services::manager::radiusd_child

=cut

=head1 DESCRIPTION

pf::services::manager::radiusd_child

Used to create the childs of the submanager radiusd
The first manager will create the config for all radiusd processes through the global variable.

=cut

use strict;
use warnings;
use Moo;
use List::MoreUtils qw(any);
use pf::file_paths qw(
    $conf_dir
    $install_dir
    $var_dir
);
use pf::util;
use pf::config qw(
    %Config
    $management_network
    %ConfigDomain
    $local_secret
);
use NetAddr::IP;
use pf::cluster;
use pfconfig::cached_array;
tie my @cli_switches, 'pfconfig::cached_array', 'resource::cli_switches';
use Template;
extends 'pf::services::manager';

has options => (is => 'rw');

our $CONFIG_GENERATED = 0;

=head2 generateConfig

Generate the configuration for ALL radiusd childs
Executed once for ALL processes

=cut

sub generateConfig {
    my ($self, $quick) = @_;

    unless($CONFIG_GENERATED){
        $self->_generateConfig();

        $CONFIG_GENERATED = 1;
    }
}

=head2 _generateConfig

Generate the configuration files for radiusd processes

=cut

sub _generateConfig {
    my ($self,$quick) = @_;
    my $tt = Template->new(ABSOLUTE => 1);
    $self->generate_radiusd_mainconf();
    $self->generate_radiusd_authconf();
    $self->generate_radiusd_acctconf();
    $self->generate_radiusd_eapconf($tt);
    $self->generate_radiusd_restconf();
    $self->generate_radiusd_sqlconf();
    $self->generate_radiusd_sitesconf();
    $self->generate_radiusd_proxy();
    $self->generate_radiusd_cluster();
    $self->generate_radiusd_cliconf();
}


=head2 generate_radiusd_sitesconf
Generates the packetfence and packetfence-tunnel configuration file
=cut

sub generate_radiusd_sitesconf {
    my %tags;

    if(isenabled($Config{advanced}{record_accounting_in_sql})){
        $tags{'accounting_sql'} = "sql";
    }
    else {
        $tags{'accounting_sql'} = "# sql not activated because explicitly disabled in pf.conf";
    }

    $tags{'template'}    = "$conf_dir/raddb/sites-included/packetfence";
    $tags{'management_ip'} = defined($management_network->tag('vip')) ? $management_network->tag('vip') : $management_network->tag('ip');
    parse_template( \%tags, "$conf_dir/radiusd/packetfence", "$install_dir/raddb/sites-included/packetfence" );
    parse_template( \%tags, "$conf_dir/radiusd/packetfence-acct", "$install_dir/raddb/sites-included/packetfence-acct" );

    %tags = ();

    if(isenabled($Config{advanced}{disable_pf_domain_auth})){
        $tags{'multi_domain'} = '# packetfence-multi-domain not activated because explicitly disabled in pf.conf';
    }
    elsif(keys %ConfigDomain){
        $tags{'multi_domain'} = 'packetfence-multi-domain';
    }
    else {
        $tags{'multi_domain'} = '# packetfence-multi-domain not activated because no domains configured';
    }

    $tags{'template'}    = "$conf_dir/raddb/sites-included/packetfence-tunnel";
    parse_template( \%tags, "$conf_dir/radiusd/packetfence-tunnel", "$install_dir/raddb/sites-included/packetfence-tunnel" );

    %tags = ();
    $tags{'template'}    = "$conf_dir/raddb/sites-included/packetfence-cli";
    $tags{'management_ip'} = defined($management_network->tag('vip')) ? $management_network->tag('vip') : $management_network->tag('ip');
    parse_template( \%tags, "$conf_dir/radiusd/packetfence-cli", "$install_dir/raddb/sites-included/packetfence-cli" );

}


=head2 generate_radiusd_mainconf
Generates the radiusd.conf configuration file
=cut

sub generate_radiusd_mainconf {
    my ($self) = @_;
    my %tags;

    $tags{'template'}    = "$conf_dir/radiusd/radiusd.conf";
    $tags{'install_dir'} = $install_dir;
    $tags{'management_ip'} = defined($management_network->tag('vip')) ? $management_network->tag('vip') : $management_network->tag('ip');
    $tags{'arch'} = `uname -m` eq "x86_64" ? "64" : "";
    $tags{'rpc_pass'} = $Config{webservices}{pass} || "''";
    $tags{'rpc_user'} = $Config{webservices}{user} || "''";
    $tags{'rpc_port'} = $Config{webservices}{aaa_port} || "7070";
    $tags{'rpc_host'} = $Config{webservices}{host} || "127.0.0.1";
    $tags{'rpc_proto'} = $Config{webservices}{proto} || "http";

    parse_template( \%tags, "$conf_dir/radiusd/radiusd.conf", "$install_dir/raddb/radiusd.conf" );
    parse_template( \%tags, "$conf_dir/radiusd/radiusd-balancer.conf", "$install_dir/raddb/radiusd-balancer.conf" );
}

sub generate_radiusd_restconf {
    my ($self) = @_;
    my %tags;

    $tags{'template'}    = "$conf_dir/radiusd/rest.conf";
    $tags{'install_dir'} = $install_dir;
    $tags{'rpc_pass'} = $Config{webservices}{pass} || "''";
    $tags{'rpc_user'} = $Config{webservices}{user} || "''";
    $tags{'rpc_port'} = $Config{webservices}{aaa_port} || "7070";
    $tags{'rpc_host'} = $Config{webservices}{host} || "127.0.0.1";
    $tags{'rpc_proto'} = $Config{webservices}{proto} || "http";

    parse_template( \%tags, "$conf_dir/radiusd/rest.conf", "$install_dir/raddb/mods-enabled/rest" );
}

sub generate_radiusd_authconf {
    my ($self) = @_;
    my %tags;
    $tags{'template'}    = "$conf_dir/radiusd/auth.conf";
    $tags{'pid_file'} = "$var_dir/run/radiusd.pid";
    $tags{'socket_file'} = "$var_dir/run/radiusd.sock";
    parse_template( \%tags, $tags{template}, "$install_dir/raddb/auth.conf" );
}

sub generate_radiusd_acctconf {
    my ($self) = @_;
    my %tags;
    $tags{'template'}    = "$conf_dir/radiusd/acct.conf";
    $tags{'pid_file'} = "$var_dir/run/radiusd-acct.pid";
    $tags{'socket_file'} = "$var_dir/run/radiusd-acct.sock";
    parse_template( \%tags, $tags{template}, "$install_dir/raddb/acct.conf" );
}

sub generate_radiusd_cliconf {
    my ($self) = @_;
    my %tags;
    if (@cli_switches > 0) {
        $tags{'template'}    = "$conf_dir/radiusd/cli.conf";
        $tags{'pid_file'} = "$var_dir/run/radiusd-cli.pid";
        $tags{'socket_file'} = "$var_dir/run/radiusd-cli.sock";
        parse_template( \%tags, $tags{template}, "$install_dir/raddb/cli.conf" );
    } else {
        my $file = $install_dir."/raddb/cli.conf";
        unlink($file);
    }
}

=head2 generate_radiusd_eapconf
Generates the eap.conf configuration file
=cut

sub generate_radiusd_eapconf {
    my ($self, $tt) = @_;
    my $radius_authentication_methods = $Config{radius_authentication_methods};
    my %vars = (
        install_dir => $install_dir,
        eap_fast_opaque_key => $radius_authentication_methods->{eap_fast_opaque_key},
        eap_fast_authority_identity => $radius_authentication_methods->{eap_fast_authority_identity},
        (map { $_ => 1 } (split ( /\s*,\s*/, $radius_authentication_methods->{eap_authentication_types} // ''))),
    );

    $tt->process("$conf_dir/radiusd/eap.conf", \%vars, "$install_dir/raddb/mods-enabled/eap") or die $tt->error();
}

=head2 generate_radiusd_sqlconf
Generates the sql.conf configuration file
=cut

sub generate_radiusd_sqlconf {
   my %tags;

   $tags{'template'}    = "$conf_dir/radiusd/sql.conf";
   $tags{'install_dir'} = $install_dir;
   $tags{'db_host'} = $Config{'database'}{'host'};
   $tags{'db_port'} = $Config{'database'}{'port'};
   $tags{'db_database'} = $Config{'database'}{'db'};
   $tags{'db_username'} = $Config{'database'}{'user'};
   $tags{'db_password'} = $Config{'database'}{'pass'};
   $tags{'hash_passwords'} = $Config{'advanced'}{'hash_passwords'} eq 'ntlm' ? 'NT-Password' : 'Cleartext-Password';

   parse_template( \%tags, "$conf_dir/radiusd/sql.conf", "$install_dir/raddb/mods-enabled/sql" );
}

=head2 generate_radiusd_proxy
Generates the proxy.conf.inc configuration file
=cut

sub generate_radiusd_proxy {
    my %tags;

    $tags{'template'} = "$conf_dir/radiusd/proxy.conf.inc";
    $tags{'install_dir'} = $install_dir;
    $tags{'config'} = '';

    foreach my $realm ( sort keys %pf::config::ConfigRealm ) {
        my $options = $pf::config::ConfigRealm{$realm}->{'options'} || '';
        $tags{'config'} .= <<"EOT";
realm $realm {
$options
}
EOT
    }
    parse_template( \%tags, "$conf_dir/radiusd/proxy.conf.inc", "$install_dir/raddb/proxy.conf.inc" );
}

=head2 generate_radiusd_cluster
Generates the load balancer configuration
=cut

sub generate_radiusd_cluster {
    my ($self) = @_;
    my %tags;

    my $int = $management_network->{'Tint'};
    my $cfg = $Config{"interface $int"};

    $tags{'members'} = '';
    $tags{'config'} ='';

    if ($cluster_enabled) {
        $tags{'template'}    = "$conf_dir/radiusd/packetfence-cluster";
        my $cluster_ip = pf::cluster::management_cluster_ip();
        $tags{'virt_ip'} = $cluster_ip;
        my @radius_backend = values %{pf::cluster::members_ips($int)};
        my $i = 0;
        foreach my $radius_back (@radius_backend) {
            next if($radius_back eq $management_network->{Tip} && isdisabled($Config{active_active}{auth_on_management}));
            $tags{'members'} .= <<"EOT";
home_server pf$i.cluster {
        type = auth+acct
        ipaddr = $radius_back
        src_ipaddr = $cluster_ip
        port = 1812
        secret = $local_secret
        response_window = 6
        status_check = status-server
        revive_interval = 120
        check_interval = 30
        num_answers_to_alive = 3
}
home_server pf$i.cli.cluster {
        type = auth
        ipaddr = $radius_back
        src_ipaddr = $cluster_ip
        port = 1815
        secret = $local_secret
        response_window = 6
        status_check = status-server
        revive_interval = 120
        check_interval = 30
        num_answers_to_alive = 3
}
EOT
            $tags{'home_server'} .= <<"EOT";
        home_server =  pf$i.cluster
EOT
            $tags{'home_server_cli'} .= <<"EOT";
        home_server =  pf$i.cli.cluster
EOT
            $i++;
        }
        parse_template( \%tags, "$conf_dir/radiusd/packetfence-cluster", "$install_dir/raddb/sites-included/packetfence-cluster" );

        %tags = ();
        $tags{'template'} = "$conf_dir/radiusd/load_balancer.conf";
        $tags{'virt_ip'} = pf::cluster::management_cluster_ip();
        $tags{'pid_file'} = "$var_dir/run/radiusd-load_balancer.pid";
        $tags{'socket_file'} = "$var_dir/run/radiusd-load_balancer.sock";
        parse_template( \%tags, $tags{'template'}, "$install_dir/raddb/load_balancer.conf");
        
        push @radius_backend, $cluster_ip;
        foreach my $radius_back (@radius_backend) {
            $tags{'config'} .= <<"EOT";
client $radius_back {
        secret = $local_secret
        ipaddr = $radius_back
        shortname = pf
}
EOT
        }

    } else {
        my $file = $install_dir."/raddb/sites-included/packetfence-cluster";
        unlink($file);
    }
    # Ensure raddb/clients.conf.inc exists. radiusd won't start otherwise.
    $tags{'template'} = "$conf_dir/radiusd/clients.conf.inc";
    parse_template( \%tags, "$conf_dir/radiusd/clients.conf.inc", "$install_dir/raddb/clients.conf.inc" );
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>


=head1 COPYRIGHT

Copyright (C) 2005-2016 Inverse inc.

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

