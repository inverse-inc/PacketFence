package pfappserver::Form::Config::PortalModule::Message;

=head1 NAME

pfappserver::Form::Config::PortalModule:Choice

=head1 DESCRIPTION

Form definition to create or update a choice portal module.

=cut

use HTML::FormHandler::Moose;
extends 'pfappserver::Form::Config::PortalModule';
with 'pfappserver::Base::Form::Role::Help';

use captiveportal::DynamicRouting::Module::Message;
sub for_module {'captiveportal::PacketFence::DynamicRouting::Module::Message'}
## Definition

has_field 'skipable' =>
  (
   type => 'Toggle',
   label => 'Skippable',
   unchecked_value => 0,
   checkbox_value => 1,
   tags => { after_element => \&help,
             help => 'Whether or not, this message can be skipped' },
  );

has_field 'message' =>
  (
   type => 'TextArea',
   label => 'Message',
   element_class => ['input-xxlarge'],
   required => 1,
   tags => { after_element => \&help,
             help => 'The message that will be displayed to the user. Use with caution as the HTML contained in this field will NOT be escaped.' },
  );

has_field 'template' =>
  (
   type => 'Text',
   label => 'Template',
   tags => { after_element => \&help,
             help => 'The template to use to display the message' },
  );

has_field 'with_layout' =>
  (
   type => 'Checkbox',
   label => 'Enable Layout',
   checkbox_value => 1,
   input_without_param => 0,
  );

sub child_definition {
    return qw(message template skipable);
}

sub BUILD {
    my ($self) = @_;
    $self->field('template')->default($self->for_module->meta->find_attribute_by_name('template')->default->());
    $self->field('skipable')->default($self->for_module->meta->find_attribute_by_name('skipable')->default->());
    $self->field('with_layout')->default($self->for_module->meta->find_attribute_by_name('with_layout')->default->());
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


