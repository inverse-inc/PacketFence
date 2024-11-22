package pfappserver::Form::Field::Path;

=head1 NAME

pfappserver::Form::Field::Path - A path field

=head1 DESCRIPTION

This field extends the default Text field and checks if the input value is an valid path

=cut

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::Text';

use pf::util;
use namespace::autoclean;

has file_type => ( is => 'rw', isa => 'Maybe[Str]' );

# If the field value matches one of the values defined in "accept", the field will pass validation.
# Otherwise, the field value must be a valid IPv4 address.

our $class_messages = {
    'path' => 'A valid path is required.',
};

sub get_class_messages {
    my $self = shift;
    return {
       %{ $self->next::method },
       %$class_messages,
    }
}

apply
  (
   [
    {
     check => sub {
         my ( $value, $field ) = @_;
         my $ft = $field->file_type;
         unless (defined $ft) {
             return -e $value;
         }

         if ($ft eq 'file') {
             return -f $value;
         }

         if ($ft eq 'dir') {
             return -d $value;
         }

         return -e $value;
     },
     message => sub {
         my ( $value, $field ) = @_;
         return $field->get_message('path');
     },
    }
   ]
  );

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

__PACKAGE__->meta->make_immutable unless $ENV{"PF_SKIP_MAKE_IMMUTABLE"};
1;
