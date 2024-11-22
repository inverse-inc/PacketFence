package pfappserver::Form::Config::PortalModule::URL;

=head1 NAME

pfappserver::Form::Config::PortalModule:URL

=head1 DESCRIPTION

Form definition to create or update a URL module.

=cut

use HTML::FormHandler::Moose;
extends 'pfappserver::Form::Config::PortalModule';
with 'pfappserver::Base::Form::Role::Help';

use captiveportal::DynamicRouting::Module::URL;
sub for_module {'captiveportal::PacketFence::DynamicRouting::Module::URL'}
## Definition

has_field 'skipable' =>
  (
   type => 'Toggle',
   label => 'Skippable',
   unchecked_value => 0,
   checkbox_value => 1,
   tags => { after_element => \&help,
             help => 'Whether or not, this redirection can be skipped.' },
  );

has_field 'url' =>
  (
   type => 'Text',
   label => 'URL',
   required => 1,
   tags => { after_element => \&help,
             help => 'The URL on which the user should be redirected.' },
  );

=head2 child_definition

Which fields defined the form

=cut

sub child_definition {
    return qw(url skipable);
}

=head2 BUILD

Override BUILD method to set the default value of the skipable field

=cut

sub BUILD {
    my ($self) = @_;
    $self->field('skipable')->default($self->for_module->meta->find_attribute_by_name('skipable')->default->());
}

=over

=back

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


