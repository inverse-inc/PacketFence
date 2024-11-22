package pf::freeradius;

=head1 NAME

pf::freeradius - FreeRADIUS configuration helper

=cut

=head1 DESCRIPTION

pf::freeradius helps with some configuration aspects of FreeRADIUS

=head1 CONFIGURATION AND ENVIRONMENT

FreeRADIUS' sql.conf and radiusd.conf should be properly configured to have the autoconfiguration benefit.
Reads the following configuration file: F<conf/switches.conf>.

=cut

# TODO move this file into the pf::services package as pf::services::freeradius.
# But first some database handling must be rewritten to depend on coderef instead of symbolic references.
use strict;
use warnings;

use Carp;
use pf::log;
use Readonly;
use List::MoreUtils qw(natatime);
use Time::HiRes qw(time);
use NetAddr::IP;

BEGIN {
    use Exporter ();
    our ( @ISA, @EXPORT );
    @ISA = qw(Exporter);
    @EXPORT = qw(
        freeradius_db_prepare
        $freeradius_db_prepared

        freeradius_populate_nas_config
    );
}

use pf::config qw($local_secret $management_network);
use pf::db;
use pf::dal::radius_nas;
use pf::dal;
use pf::util qw(valid_mac);
use pf::error qw(is_error);
use pf::cluster;

# The next two variables and the _prepare sub are required for database handling magic (see pf::db)
our $freeradius_db_prepared = 0;
# in this hash reference we hold the database statements. We pass it to the query handler and he will repopulate
# the hash if required
our $freeradius_statements = {};


=head1 SUBROUTINES

=over

=head2 freeradius_db_prepare

Prepares all the SQL statements related to this module

=cut

sub _delete_expired {
    my ($timestamp) = @_;
    my $logger = get_logger();
    my ($status, $rows) = pf::dal::radius_nas->remove_items(
        -where => {
            config_timestamp => {"!=" => $timestamp},
        },
    );
    $logger->debug("emptying radius_nas table");
    if (is_error($status)) {
        return undef;
    }

    return $rows;
}

=head2 _insert_nas_bulk

Add a new NAS (FreeRADIUS client) record

=cut

sub _insert_nas_bulk {
    my (@rows) = @_;
    my $logger = get_logger();
    return 0 unless @rows;
    my $sqla = pf::dal::radius_nas->get_sql_abstract;
    my ($sql, @bind) = $sqla->update_multi(
        'radius_nas',
        [qw(nasname shortname secret description config_timestamp start_ip end_ip range_length)],
        \@rows
    );
    my ($status, $sth) = pf::dal::radius_nas->db_execute($sql, @bind);
    if (is_error($status)) {
        return 0;
    }

    $sth->finish;
    return 1;
}

=head2 freeradius_populate_nas_config

Populates the radius_nas table with switches in switches.conf.

=cut

my %skip = (default => undef, '127.0.0.1' => undef);

# First, we aim at reduced complexity. I prefer to dump and reload than to deal with merging config vs db changes.
sub freeradius_populate_nas_config {
    my $logger = get_logger();
    unless(db_ping()){
        $logger->error("Can't connect to db");
        return;
    }

    if (db_readonly_mode()) {
        my $msg = "Cannot reload the RADIUS clients table when the database is in read only mode\n";
        print STDERR $msg;
        $logger->error($msg);
        return;
    }
    my ($switch_config, $timestamp) = @_;
    my $radiusSecret;

    #Only switches with a secert except default and 127.0.0.1
    my @switches = grep {
            $_ !~ /^group /
          && !exists $skip{$_}
          && defined( $radiusSecret = $switch_config->{$_}{radiusSecret} )
          && $radiusSecret =~ /\S/
    } keys %$switch_config;
    return unless @switches;
    #Should be handled in code above this
    unless (defined $timestamp ) {
        $timestamp = int (time * 1000000);
    }

    my @entries = (
        (map { { %{$switch_config->{$_}}, id => $_ } } @switches),
        additional_switches(),
    );
    #Looping through all the switches 100 at a time
    my $it = natatime 100, @entries;
    while (my @sw = $it->()) {
        my @rows = map {
            _build_radius_nas_row($_->{id}, $_, $timestamp)
        } @sw;
        # insert NAS
        _insert_nas_bulk( @rows );
    }
    _delete_expired($timestamp);
    validate_radius_nas_table($timestamp);
}

sub additional_switches {
    my @switches;

    if ($cluster_enabled) {
        while (my (undef, $entries) = each(%all_cluster_sections)) {
            push @switches, map {
                {
                    id            => $_->{management_ip},
                    radiusSecret  => $local_secret,
                    type          => 'PacketFence'
                }
            } (@$entries);
        }
    }


    return @switches;
}

our $validate_radius_nas_table_sql = <<SQL;
    SELECT
        (SELECT COUNT(1) FROM radius_nas) = (SELECT COUNT(1) FROM radius_nas WHERE config_timestamp = ?) AS config_valid,
        (SELECT COUNT(DISTINCT config_timestamp) FROM radius_nas WHERE config_timestamp != ?) as other_processes;
SQL

=head2 validate_radius_nas_table

validate radius nas table

=cut

sub validate_radius_nas_table {
    my $logger = get_logger();
    my ($ts) = @_;
    my $validation = validation_results($ts);
    if (!$validation->{config_valid}) {
        if ($validation->{other_processes}) {
            my $msg = "The radius_nas table is invalid.\nAt least $validation->{other_processes} reloaded\nrerun 'pfcmd configreload' on a single server\n";
            print STDERR $msg;
            $logger->error($msg);
        }
    }
    return ;
}

=head2 validation_results

validation_results

=cut

sub validation_results {
    my ($timestamp) = @_;
    my $logger = get_logger();
    my ($status, $sth) = pf::dal->db_execute($validate_radius_nas_table_sql, $timestamp, $timestamp);
    if (is_error($status)) {
        my $msg = "Problem connecting to the database to verify radius_nas table\n";
        print STDERR $msg;
        $logger->error($msg);
        return undef;
    }

    my $validation = $sth->fetchrow_hashref;
    $sth->finish;
    return $validation;
}

=head2 _build_radius_nas_row

=cut

sub _build_radius_nas_row {
    my ($id, $data, $timestamp) = @_;
    my $start_ip = 0;
    my $end_ip = 0;
    my $range_length = 0;
    unless (valid_mac($id)) {
        if(my $netaddr = NetAddr::IP->new($id)) {
            $start_ip = $netaddr->first->numeric;
            $end_ip = $netaddr->last->numeric;
            $range_length = $end_ip - $start_ip + 1;
        }
    }
    [ $id, $id, $data->{radiusSecret}, $id . " (" . $data->{'type'} .")", $timestamp, $start_ip, $end_ip, $range_length]
}

=back

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
