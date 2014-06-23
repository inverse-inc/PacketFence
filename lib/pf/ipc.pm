package pf::ipc;

=head1 NAME

pf::ipc - extended Redis::Fast class for IPC communication within PacketFence.

=head1 SYNOPSIS

    use pf::ipc;
    use Data::Dumper;

    my $ipc = pf::ipc->new(); # accepts any of the Redis::Fast arguments.

    #strings
    $ipc->enqueue('messages', 'hello world');

    #refs
    $ipc->enqueue('messages', { msg => 'hello world' });
    $ipc->enqueue('messages', [ 'hello','world' ]);

    my $item = $ipc->dequeue('messages');

    my $count = $ipc->queueCount('messages');

    $ipc->subscribe(
        'subtest',
        sub {
            # handles de-serialization
            my $message = $ipc->pfSubscribeHandler(@_);
            print Dumper $message;
            ...
        }
    );

    # supply a code ref
    $ipc->subscribe( 'subtest',\&messagehandler );

    # subscribe to a pattern of topics
    $ipc->psubscribe('ipc.*',sub { ... });

    # pfpublish handles serializing
    $ipc->pfpublish('subtest',{ this => 'is a test'});
    $ipc->pfpublish('subtest','and so is this');
    $ipc->pfpublish( 'subtest',[ 'this','too'] );



=head1 DESCRIPTION

This class extends Redis::Fast. All functions in Redis::Fast are preserved. Helper methods have been added for queueing and subscription serialization handling. This allows fast communication between processes via lists, hashes, subscriptions, and key/val. Please see the documentation for Redis.pm for more information on the Redis methods.

Currently it is up to the developer to make sure the data is consisten between queues, i.e array refs vs hash refs vs strings.

In the future I may add a registration process to ensure data consistency. 

=cut

use Moose;
use MooseX::NonMoose;
extends 'Redis::Fast';

# used Storable for objects and JSON for things that may need to be human readable
use JSON::XS;
use Storable;

has 'encoder' => (is => 'ro', default => sub { JSON::XS->new; });

sub FOREIGNBUILDARGS {
    my $class = shift;
    my %args = shift;
    # make modifications
    return %args;
}

sub enqueue {
    my ($self,$q,$item) = @_;
    my $txt;
    if ( ref($item) ) {
        $txt = $self->encoder->encode( $item );
    }
    else {
        $txt = $item;
    }
    $self->rpush($q,$txt);

}

sub dequeue {
    my ($self,$q) = @_;
    my $txt = $self->lpop($q);
    my $ret;
    if ($txt =~ /(\{|\[)/) {
        $ret = $self->encoder->decode($txt);
    }
    else {
        $ret = $txt;
    }
    return $ret;
}

# I hate camel case...
sub queueCount {
    my ($self,$q) = @_;
    return $self->llen($q);
}

sub pfpublish {
    my ($self,$topic,$item) = @_;
    my $txt;
    if ( ref($item) ) {
        $txt = $self->encoder->encode( $item );
    }
    else {
        $txt = $item;
    }
    $self->publish($topic,$txt);

}

# i hate HungarianNotation
sub pfSubscribeHandler {
    my ($self,$message,$topic,$subscribed_topic) = @_;
    my $ret;
    if ($message =~ /(\{|\[)/) {
        $ret = $self->encoder->decode($message);
    }
    else {
        $ret = $message;
    }
    return $ret;
}

sub lcache {
    my ($self,$key,$ttl,$ref) = @_;
    $self->cache($key,$ttl,$ref,$$);
}

sub cache {
    my ($self,$key,$ttl,$ref,$prepend) = @_;
    my $return;
    # use pid for per process cache.
    $ttl = 300 if (not $ttl); # default to 5 minutes 
    if ($prepend) {
        $key = $prepend.'_'.$key;
    }

    die "no coderef in lcache\n" if not $ref;

    my $resp = $self->get($key);
    if ($resp) {
        $return = Storable::thaw($resp);
    }
    else {
        $return = $ref->();
        $self->set($key,Storable::freeze($return));
        $self->expire($key,$ttl);
    }
    return $return;
}

no Moose;

__PACKAGE__->meta->make_immuntable;

=head1 FUTURE

   - add support for auto connection based on config
   - add support for sentinals

=head1 AUTHOR

mullagain <m5mulli@gmail.com>

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
