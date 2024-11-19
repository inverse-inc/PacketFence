package pfappserver::Form::Config::Kafka;

=head1 NAME

pfappserver::Form::Config::Kafka -

=head1 DESCRIPTION

pfappserver::Form::Config::Kafka

=cut

use strict;
use warnings;
use HTML::FormHandler::Moose;
extends 'pfappserver::Base::Form';
with 'pfappserver::Base::Form::Role::Help';

has_field 'iptables' => (
    type => 'Compound',
);

has_field 'iptables.clients' => (
   type => 'Repeatable',
);

has_field 'iptables.clients.contains' => (
   type => 'IPAddress',
);

has_field 'iptables.cluster_ips' => (
   type => 'Repeatable',
);

has_field 'iptables.cluster_ips.contains' => (
   type => 'IPAddress',
);

has_field 'iptables.admin' => (
   type => 'Compound',
);

has_field 'iptables.admin.user' => (
   type => 'Text',
);

has_field 'iptables.admin.pass' => (
   type => 'ObfuscatedText',
);

has_field 'iptables.auths' => (
   type => 'Repeatable',
);

has_field 'iptables.auths.contains' => (
   type => 'UserPass',
);

has_field 'iptables.auths.contains' => (
   type => 'UserPass',
);

has_field 'iptables.host_configs' => (
   type => 'Compound',
);

has_field 'iptables.host_configs.host' => (
   type => 'Text',
);

has_field 'iptables.host_configs.config' => (
   type => 'Repeatable',
);

has_field 'iptables.host_configs.config.contains' => (
   type => 'NameVal',
);

has_field 'iptables.cluster' => (
   type => 'Repeatable',
);

has_field 'iptables.cluster.contains' => (
   type => 'NameVal',
);

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
