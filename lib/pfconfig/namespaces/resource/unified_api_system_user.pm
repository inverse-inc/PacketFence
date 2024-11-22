package pfconfig::namespaces::resource::unified_api_system_user;

=head1 NAME

pfconfig::namespaces::resource::unified_api_system_user

=cut

=head1 DESCRIPTION

pfconfig::namespaces::resource::unified_api_system_user

=cut

use strict;
use warnings;

use base 'pfconfig::namespaces::resource';

use pf::file_paths qw($unified_api_system_pass_file);
use File::Slurp qw(read_file);

sub init {
    my ($self, $cluster_name) = @_;

    $self->{child_resources} = ['config::Connector'];
}

sub build {
    my ($self) = @_;
    my $pass = read_file($unified_api_system_pass_file);

    return {
        user => "system",
        pass => $pass,
    };
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

# vim: set shiftwidth=4:
# vim: set expandtab:
# vim: set backspace=indent,eol,start:
