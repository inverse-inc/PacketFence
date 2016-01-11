package pfappserver::Model::Config::SwitchGroup;
=head1 NAME

pfappserver::Model::Config::SwitchGroup

=cut

=head1 DESCRIPTION

pfappserver::Model::Config::SwitchGroup;

=cut

use Moose;
use namespace::autoclean;
use pf::ConfigStore::SwitchGroup;
use HTTP::Status qw(:constants :is);

extends 'pfappserver::Base::Model::Config';


=head2 Methods

=over

=item _buildConfigStore

=cut

sub _buildConfigStore { pf::ConfigStore::SwitchGroup->new; }

=head2 remove

Override the parent method to validate we don't remove a group that has childs

=cut

sub remove {
    my ($self, $id) = @_;
    pf::log::get_logger->info("Deleting $id");
    my @childs = $self->configStore->members($id, $self->idKey);
    if(@childs){
        my @switch_ids = map { $_->{id} } @childs;
        my $switch_csv = join(', ', @switch_ids);
        my $status_msg = ["Cannot remove group [_1] because it is still used by the following switches : [_2]",$id, $switch_csv];
        my $status =  HTTP_PRECONDITION_FAILED;
        return ($status, $status_msg);
    }
    else {
        return $self->SUPER::remove($id);
    }
}

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


