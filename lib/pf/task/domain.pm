package pf::task::domain;

=head1 NAME

pf::task::domain

=cut

=head1 DESCRIPTION

Task to perform long-running AD domain operations (join, unjoin, rejoin)

=cut

use strict;
use warnings;
use base 'pf::task';
use pf::domain;
use pf::log;
use pf::config qw(%ConfigDomain);
use pf::constants::pfqueue qw($STATUS_FAILED);
use pf::ConfigStore::Domain;

our %OP_MAP = (
    join => \&pf::domain::join_domain,
    unjoin => \&pf::domain::unjoin_domain,
    rejoin => \&pf::domain::rejoin_domain,
    test_join => \&pf::domain::test_join,
);

=head2 doTask

Log to pfqueue.log

=cut

sub doTask {
    my ($self, $args) = @_;
    my $logger = get_logger;

    my $op = $args->{operation} // '<null>';
    my $domain = $args->{domain};

    unless (defined $op && exists($OP_MAP{$op})) {
        my $msg = "Invalid operation $op for domain";
        $logger->error($msg);
        return { message => $msg, status => 405 }, undef;
    }

    unless (exists($ConfigDomain{$domain})) {
        my $msg = "Invalid domain $domain for domain task";
        $logger->error($msg);
        return { message => $msg, status => 404 }, undef;
    }

    my $info = {%{$ConfigDomain{$domain}}};
    if ($args) {
        for my $k (qw(bind_dn bind_pass)) {
            my $v = $args->{$k};
            next unless defined $v && length($v);
            $info->{$k} = $v;
        }
    }

    return $OP_MAP{$op}->($domain, $info);
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

