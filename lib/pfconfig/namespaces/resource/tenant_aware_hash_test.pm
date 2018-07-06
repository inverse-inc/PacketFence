package pfconfig::namespaces::resource::tenant_aware_hash_test;

=head1 NAME

pfconfig::namespaces::resource::tenant_aware_hash_test -

=cut

=head1 DESCRIPTION

pfconfig::namespaces::resource::tenant_aware_hash_test

=cut

use strict;
use warnings;
use base 'pfconfig::namespaces::resource';

sub init {
    my ($self) = @_;
    $self->{_scoped_by_tenant_id} = 1;
}

sub build {
    my ($self) = @_;
    return {
        1 => {
            'inverse.ca' => {
                'admin_strip_username'  => 'disabled',
                'portal_strip_username' => 'enabled',
            }
        },
        2 => {
            'bob.com' => {
                'admin_strip_username'  => 'enabled',
                'portal_strip_username' => 'disabled',
            }
        }
    };
}


=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2018 Inverse inc.

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
