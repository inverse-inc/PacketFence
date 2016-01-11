package pf::ConfigStore::SwitchGroup;
=head1 NAME

pf::ConfigStore::SwitchGroup

=cut

=head1 DESCRIPTION

pf::ConfigStore::SwitchGroup;

=cut

use Moo;
use namespace::autoclean;
use pf::ConfigStore::Pf;
use pf::ConfigStore::Group;

extends 'pf::ConfigStore::Switch';
with 'pf::ConfigStore::Group';
with 'pf::ConfigStore::Hierarchy';

sub group { 'group' };

sub globalConfigStore { pf::ConfigStore::Switch->new }

__PACKAGE__->meta->make_immutable;

=back

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


