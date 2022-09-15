package pf::connector;

use Moo;
use URI;
use pf::api::unifiedapiclient;
use POSIX::AtFork;
use pf::config qw(%Config);

has id => (is => 'rw');

has secret => (is => 'rw');

has networks => (is => 'rw');

my %connections;
my $redis;
sub CLONE {
    %connections = ();
    $redis = undef;
}
POSIX::AtFork->add_to_child(\&CLONE);
CLONE();

sub connect_redis {
    if($redis) {
        return $redis;
    }
    else {
        $redis = pf::Redis->new(server => $Config{pfconnector}{redis_server});
        return $redis;
    }
}

sub connectorServerApiClient {
    my ($self) = @_;
    #TODO: get this out of redis_queue
    my $redis = $self->connect_redis;
    if(my $server = $redis->get($Config{pfconnector}{redis_tunnels_namespace}.$self->id)) {
        if(exists($connections{$server})) {
            return $connections{$server};
        }
        my $uri = URI->new($server);
        $connections{$server} = pf::api::unifiedapiclient->new(proto => $uri->scheme, host => $uri->host, port => $uri->port);
        return $connections{$server};
    }
    else {
        return pf::api::unifiedapiclient->default_client;
    }
}

sub dynreverse {
    my ($self, $to) = @_;
    my $connector_conn = $self->connectorServerApiClient->call("POST", "/api/v1/pfconnector/dynreverse", {
        to => $to,
        connector_id => $self->id,
    });

    #Override the host value if this is a container so that it always goes through the local containers interface
    #Otherwise the UDP packets don't get an answer because the docker proxy doesn't get them back on the containers network
    #This shouldn't apply to K8S containers, only when running containers on a 'Classic PF'
    if($ENV{IS_A_CLASSIC_PF_CONTAINER}) {
        $connector_conn->{host} = "containers-gateway.internal";
    }
    return $connector_conn;
}

1;

