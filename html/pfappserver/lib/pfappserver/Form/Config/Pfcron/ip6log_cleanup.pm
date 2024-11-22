package pfappserver::Form::Config::Pfcron::ip6log_cleanup;

=head1 NAME

pfappserver::Form::Config::Pfcron::ip6log_cleanup - Web form for ip6log_cleanup pfcron task

=head1 DESCRIPTION

Web form for ip6log_cleanup pfcron task

=cut

use HTML::FormHandler::Moose;

use pfappserver::Form::Config::Pfcron qw(default_field_method batch_help_text timeout_help_text window_help_text);

extends 'pfappserver::Form::Config::Pfcron';
with 'pfappserver::Base::Form::Role::Help';

has_field 'batch' => (
    type => 'PosInteger',
    default_method => \&default_field_method,
    tags => { after_element => \&help,
             help => \&batch_help_text },
);

has_field 'rotate' => (
    type => 'Toggle',
    checked_value => 'enabled',
    unchecked_value => 'disabled',
    default_method => \&default_field_method,
    tags => { after_element => \&help,
             help => 'Enable or disable ip6log rotation (moving ip6log_history records to ip6log_archive)<br>If disabled, this task will delete from the ip6log_history table rather than the ip6log_archive.' },
);

has_field 'rotate_batch' => (
    type => 'PosInteger',
    default_method => \&default_field_method,
    tags => { after_element => \&help,
             help => \&batch_help_text },
);

has_field 'rotate_timeout' => (
    type => 'Duration',
    default_method => \&default_field_method,
    tags => { after_element => \&help,
             help => \&timeout_help_text },
);

has_field 'rotate_window' => (
    type => 'Duration',
    default_method => \&default_field_method,
    tags => { after_element => \&help,
             help => 'How long to keep ip6log history entry before rotating it to ip6log archive.' },
);

has_field 'timeout' => (
    type => 'Duration',
    default_method => \&default_field_method,
    tags => { after_element => \&help,
             help => \&timeout_help_text },
);

has_field 'window' => (
    type => 'Duration',
    default_method => \&default_field_method,
    tags => { after_element => \&help,
             help => 'How long to keep a ip6log archive entry before deleting it (or ip6log history if rotation is disabled)' },
);


=head2 default_type

default value of type

=cut

sub default_type {
    return "ip6log_cleanup";
}

has_block  definition =>
  (
    render_list => [qw(type status interval batch timeout window rotate rotate_batch rotate_timeout rotate_window)],
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
