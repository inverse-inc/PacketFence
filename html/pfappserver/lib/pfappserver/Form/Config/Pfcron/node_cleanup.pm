package pfappserver::Form::Config::Pfcron::node_cleanup;

=head1 NAME

pfappserver::Form::Config::Pfcron::node_cleanup - Web form for node_cleanup pfcron task

=head1 DESCRIPTION

Web form for node_cleanup pfcron task

=cut

use HTML::FormHandler::Moose;

use pfappserver::Form::Config::Pfcron qw(default_field_method batch_help_text timeout_help_text window_help_text);

extends 'pfappserver::Form::Config::Pfcron';
with 'pfappserver::Base::Form::Role::Help';

has_field 'unreg_window' => (
    type => 'Duration',
    default_method => \&default_field_method,
    tags => { after_element => \&help,
             help => 'How long can a registered node be inactive on the network before it becomes unregistered' },
);

has_field 'delete_window' => (
    type => 'Duration',
    default_method => \&default_field_method,
    tags => { after_element => \&help,
             help => 'How long can an unregistered node be inactive on the network before being deleted.<br>This shouldn\'t be used if you are using port-security' },
);

has_field 'voip' =>  (
   type => 'Toggle',
   checkbox_value => 'enabled',
   unchecked_value => 'disabled',
   default_method => \&default_field_method,
    tags => { after_element => \&help,
             help => 'Enable voip device cleanup' },
);

has_field 'batch' => (
    type => 'PosInteger',
    default_method => \&default_field_method,
    tags => { after_element => \&help,
             help => \&batch_help_text },
);

has_field 'timeout' => (
    type => 'Duration',
    default_method => \&default_field_method,
    tags => { after_element => \&help,
             help => \&timeout_help_text },
);

=head2 default_type

default value of type

=cut

sub default_type {
    return "node_cleanup";
}

has_block  definition =>
  (
    render_list => [qw(type status voip interval unreg_window delete_window)],
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
