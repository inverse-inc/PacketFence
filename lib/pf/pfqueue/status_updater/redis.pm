package pf::pfqueue::status_updater::redis;

=head1 NAME

pf::pfqueue::status_updater::redis

=cut

=head1 DESCRIPTION

Updates the status of a job via Redis storage

=cut

use strict;
use warnings;

use Moo;
use pf::constants::pfqueue qw(
    $STATUS_FAILED
    $STATUS_COMPLETED
    $STATUS_IN_PROGRESS
    $FAILED_MSG
    $STATUS_MSG_KEY
    $COMPLETED_MSG
    $IN_PROGRESS_MSG
    $STATUS_KEY
    $MSG_KEY
    $ERROR_KEY
    $SUB_TASKS_KEY
    $CURRENT_SUB_TASK_KEY
    $PROGRESS_KEY
    $RESULT_KEY
);
use JSON::MaybeXS;
use pf::constants;
use pf::log;

sub empty {};

=head2 connection

The Redis connnection

=cut

has 'connection' => (is => 'rw', required => 1);

=head2 task_id

The current task ID to update the status for

=cut

has 'task_id' => (is => 'rw', required => 1, trigger => \&reset_state);

=head2 status_ttl

How long should the status be available after the job has been initially started
The TTL gets extended everytime something is inserted in the status hash in Redis

=cut

has 'status_ttl' => (is => 'rw', default => sub{60*15});

=head2 finalized

Whether or not the job is finalized (no more updates to the status should be accepted)

=cut

has 'finalized' => (is => 'rw', default => sub{$FALSE});

=head2 reset_state

Handle reseting the state of the object after a task ID change

=cut

sub reset_state {
    my ($self) = @_;
    get_logger->trace("Setting new task ID, resetting state");
    $self->finalized($FALSE);
}


=head2 start

start

=cut

sub start {
    my ($self) = @_;
    $self->set_in_status_hash(
        $PROGRESS_KEY => 0,
        $STATUS_KEY => $STATUS_IN_PROGRESS,
        $MSG_KEY => $IN_PROGRESS_MSG
    );
    return ;
}

=head2 save_results

save_results

=cut

sub save_results {
    my ($self, $results_key, $results, $status, $message, @extra) = @_;
    $results = encode_json($results);
    $self->set_in_status_hash(
        $results_key => $results, 
        $STATUS_KEY => $status,
        $PROGRESS_KEY => 100,
        $MSG_KEY => $message,
        @extra
    );
    return ;
}

=head2 failed

Set task as failed

=cut

sub failed {
    my ($self, $error) = @_;
    $self->save_results($ERROR_KEY, $error, $STATUS_FAILED, $FAILED_MSG);
    $self->finalized($TRUE);
    return ;
}

=head2 completed

completed

=cut

sub completed {
    my ($self, $results) = @_;
    $self->save_results($RESULT_KEY, $results, $STATUS_COMPLETED, $COMPLETED_MSG);
    $self->finalized($TRUE);
    return ;
}

=head2 update_progress

Update progress and optionally the message of the task status
The progress will normalized to be between 0 and 99
The progress can only be set to 100 by $su->completed($results) or $su->failed($err)

=cut

sub update_progress {
    my ($self, $progress, $message) = @_;
    if ($progress < 0) {
        $progress = 0;
    } elsif ($progress >= 100) {
        $progress = 99;
    }

    $self->set_in_status_hash(
        $PROGRESS_KEY => $progress,
        (defined $message ? ($MSG_KEY => $message) : () ),
    );
    return ;
}

=head2 update_message

Set the message for the job

=cut

sub update_message {
    my ($self, $msg) = @_;
    $self->set_in_status_hash($MSG_KEY, $msg);
}

=head2 finalize

Finalize a job which stops all status updates

=cut

sub finalize {
    my ($self) = @_;
    $self->finalized($TRUE);
}

=head2 set_in_status_hash

Set attributes in the status hash and notify any subscriber of the change

=cut

sub set_in_status_hash {
    my ($self, @data) = @_;
    my $status_key = $self->status_key;
    if ($self->finalized) {
        get_logger->trace("Not saving data for $status_key since status has been finalized");
        return;
    }

    my $publish_key = $self->status_publish_key;
    my $connection = $self->connection;
    $connection->multi(\&empty);
    $connection->hmset($status_key, @data, \&empty);
    $connection->expire($status_key, $self->status_ttl, \&empty);
    $connection->del($publish_key, \&empty);
    $connection->rpush($publish_key, 1, \&empty);
    $connection->exec(\&empty);
    $connection->wait_all_responses();
}

=head2 status_key

Status key for the current task ID

=cut

sub status_key {
    my ($self) = @_;
    return $self->task_id."-Status";
}

=head2 status_publish_key

Status publish key for the current task ID

=cut

sub status_publish_key {
    my ($self) = @_;
    return $self->status_key . "-Updates";
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

