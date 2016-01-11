package pf::radius_audit_log;

=head1 NAME

pf::radius_audit_log - module for radius_audit_log management.

=cut

=head1 DESCRIPTION

pf::radius_audit_log contains the functions necessary to manage a radius_audit_log: creation,
deletion, read info, ...

=cut

use strict;
use warnings;
use constant RADIUS_AUDIT_LOG => 'radius_audit_log';

BEGIN {
    use Exporter ();
    our ( @ISA, @EXPORT, @EXPORT_OK );
    @ISA = qw(Exporter);
    @EXPORT = qw(
        $radius_audit_log_db_prepared
        radius_audit_log_db_prepare
        radius_audit_log_delete
        radius_audit_log_add
        radius_audit_log_view
        radius_audit_log_count_all
        radius_audit_log_view_all
        radius_audit_log_custom
    );
}

use pf::log;
use pf::db;

# The next two variables and the _prepare sub are required for database handling magic (see pf::db)
our $radius_audit_log_db_prepared = 0;
# in this hash reference we hold the database statements. We pass it to the query handler and he will repopulate
# the hash if required
our $radius_audit_log_statements = {};

our $logger = get_logger();

our @FIELDS = qw(
    mac
    ip
    computer_name
    user_name
    stripped_user_name
    realm
    event_type
    switch_id
    switch_mac
    switch_ip_address
    radius_source_ip_address
    called_station_id
    calling_station_id
    nas_port_type
    ssid
    nas_port_id
    ifindex
    nas_port
    connection_type
    nas_ip_address
    nas_identifier
    auth_status
    reason
    auth_type
    eap_type
    role
    node_status
    profile
    source
    auto_reg
    is_phone
    pf_domain
    uuid
    radius_request
    radius_reply
);

our @NODE_FIELDS = qw(
    mac
    ip
    computer_name
    user_name
    stripped_user_name
    realm
    calling_station_id
    auth_type
    eap_type
    auth_status
    reason
    role
    node_status
    profile
    source
    auto_reg
    is_phone
    pf_domain
    uuid
);

our @RADIUS_FIELDS = qw(radius_request radius_reply);

our %RADIUS_FIELDS = map { $_ => 1 } @RADIUS_FIELDS;

our @SWITCH_FIELDS = qw(
    switch_id
    switch_mac
    switch_ip_address
    radius_source_ip_address
    called_station_id
    nas_port_type
    ssid
    nas_port_id
    ifindex
    nas_port
    connection_type
    nas_ip_address
    nas_identifier
);

our $FIELD_LIST = join(", ",@FIELDS);

our $INSERT_LIST = join(", ", ("?") x @FIELDS);

=head1 SUBROUTINES

=head2 radius_audit_log_db_prepare()

Prepare the sql statements for radius_audit_log table

=cut

sub radius_audit_log_db_prepare {
    $logger->debug("Preparing pf::radius_audit_log database queries");
    my $dbh = get_db_handle();

    $radius_audit_log_statements->{'radius_audit_log_add_sql'} = $dbh->prepare(
        qq[ INSERT INTO radius_audit_log ( $FIELD_LIST ) VALUES ( $INSERT_LIST ) ]);

    $radius_audit_log_statements->{'radius_audit_log_view_sql'} = $dbh->prepare(
        qq[ SELECT id, created_at, $FIELD_LIST FROM radius_audit_log WHERE id = ? ]);

    $radius_audit_log_statements->{'radius_audit_log_view_all_sql'} = $dbh->prepare(
        qq[ SELECT id, created_at, $FIELD_LIST FROM radius_audit_log ORDER BY id LIMIT ?, ? ]);

    $radius_audit_log_statements->{'radius_audit_log_count_all_sql'} = $dbh->prepare( qq[ SELECT count(*) as count FROM radius_audit_log ]);

    $radius_audit_log_statements->{'radius_audit_log_delete_sql'} = $dbh->prepare(qq[ delete from radius_audit_log where pid=? ]);

    $radius_audit_log_statements->{'radius_audit_log_cleanup_sql'} = $dbh->prepare(
        qq [ delete from radius_audit_log where created_at < DATE_SUB(?, INTERVAL ? SECOND) and end_time != 0 LIMIT ?]);

    $radius_audit_log_db_prepared = 1;
}


=head2 $success = radius_audit_log_delete($id)

Delete a radius_audit_log entry

=cut

sub radius_audit_log_delete {
    my ($id) = @_;
    db_query_execute(RADIUS_AUDIT_LOG, $radius_audit_log_statements, 'radius_audit_log_delete_sql', $id) || return (0);
    $logger->info("radius_audit_log $id deleted");
    return (1);
}


=head2 $success = radius_audit_log_add(%args)

Add a radius_audit_log entry

=cut

sub radius_audit_log_add {
    my %data = @_;
    db_query_execute(RADIUS_AUDIT_LOG, $radius_audit_log_statements, 'radius_audit_log_add_sql', @data{@FIELDS}) || return (0);
    return (1);
}

=head2 $entry = radius_audit_log_view($id)

View a radius_audit_log entry by it's id

=cut

sub radius_audit_log_view {
    my ($id) = @_;
    my $query  = db_query_execute(RADIUS_AUDIT_LOG, $radius_audit_log_statements, 'radius_audit_log_view_sql', $id)
        || return (0);
    my $ref = $query->fetchrow_hashref();
    # just get one row and finish
    $query->finish();
    return ($ref);
}

=head2 $count = radius_audit_log_count_all()

Count all the entries radius_audit_log

=cut

sub radius_audit_log_count_all {
    my $query = db_query_execute(RADIUS_AUDIT_LOG, $radius_audit_log_statements, 'radius_audit_log_count_all_sql');
    my @row = $query->fetchrow_array;
    $query->finish;
    return $row[0];
}

=head2 @entries = radius_audit_log_view_all($offset, $limit)

View all the radius_audit_log for an offset limit

=cut

sub radius_audit_log_view_all {
    my ($offset, $limit) = @_;
    $offset //= 0;
    $limit  //= 25;

    return db_data(RADIUS_AUDIT_LOG, $radius_audit_log_statements, 'radius_audit_log_view_all_sql', $offset, $limit);
}

sub radius_audit_log_cleanup {
    my $timer = pf::StatsD::Timer->new({sample_rate => 0.2});
    my ($expire_seconds, $batch, $time_limit) = @_;
    my $logger = get_logger();
    $logger->debug(sub { "calling radius_audit_log_cleanup with time=$expire_seconds batch=$batch timelimit=$time_limit" });
    my $now = db_now();
    my $start_time = time;
    my $end_time;
    my $rows_deleted = 0;
    while (1) {
        my $query = db_query_execute(RADIUS_AUDIT_LOG, $radius_audit_log_statements, 'radius_audit_log_cleanup_sql', $now, $expire_seconds, $batch)
        || return (0);
        my $rows = $query->rows;
        $query->finish;
        $end_time = time;
        $rows_deleted+=$rows if $rows > 0;
        $logger->trace( sub { "deleted $rows_deleted entries from radius_audit_log during radius_audit_log cleanup ($start_time $end_time) " });
        last if $rows == 0 || (( $end_time - $start_time) > $time_limit );
    }
    $logger->trace( "deleted $rows_deleted entries from radius_audit_log during radius_audit_log cleanup ($start_time $end_time) " );
    return (0);
}

=head2 @entries = radius_audit_log_custom($sql, @args)

Custom sql query for radius audit log

=cut

sub radius_audit_log_custom {
    my ($sql, @args) = @_;
    $radius_audit_log_statements->{'radius_audit_log_custom_sql'} = $sql;
    return db_data(RADIUS_AUDIT_LOG, $radius_audit_log_statements, 'radius_audit_log_custom_sql', @args);
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2015 Inverse inc.

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
