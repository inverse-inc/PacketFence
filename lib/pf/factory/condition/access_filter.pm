package pf::factory::condition::access_filter;

=head1 NAME

pf::factory::condition::access_filter

=cut

=head1 DESCRIPTION

pf::factory::condition::access_filter

=cut

use strict;
use warnings;
use Module::Pluggable search_path => 'pf::condition', sub_name => '_modules', require => 1;
use pf::config::util qw(str_to_connection_type);

our @MODULES;

sub factory_for {'pf::condition'}

our %VLAN_FILTER_TYPE_TO_CONDITION_TYPE = (
    'is'          => 'pf::condition::equals',
    'is_not'      => 'pf::condition::not_equals',
    'match'       => 'pf::condition::matches',
    'match_not'   => 'pf::condition::not_matches',
    'defined'     => 'pf::condition::is_defined',
    'not_defined' => 'pf::condition::not_defined',
);

our %VLAN_FILTER_KEY_TYPES = (
    'node_info'      => 1,
    'switch'         => 1,
    'owner'          => 1,
    'radius_request' => 1,
);

sub modules {
    my ($class) = @_;
    unless (@MODULES) {
        @MODULES = $class->_modules;
    }
    return @MODULES;
}

__PACKAGE__->modules;

sub instantiate {
    my ($class, $data) = @_;
    my $filter = $data->{filter};
    if ($filter eq 'time') {
        my $c = pf::condition::time_period->new({value => $data->{value}});
        if ($data->{operator} eq 'is_not') {
            return pf::condition::not->new({condition => $c});
        }
        return $c;
    }
    my $sub_condition = _build_sub_condition($data);
    return _build_parent_condition($sub_condition, (split /\./, $filter));
}

sub _build_parent_condition {
    my ($child, $key, @parents) = @_;
    if (@parents == 0) {
        return pf::condition::key->new({
            key       => $key,
            condition => $child,
        });
    }
    return pf::condition::key->new({
        key       => $key,
        condition => _build_parent_condition($child, @parents),
    });
}

sub _build_sub_condition {
    my ($data) = @_;
    my $condition_class = $VLAN_FILTER_TYPE_TO_CONDITION_TYPE{$data->{operator}};
    my $value = $data->{filter} eq 'connection_type' ? str_to_connection_type($data->{value}) : $data->{value};
    return $condition_class ? $condition_class->new({value => $value}) : undef;
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
