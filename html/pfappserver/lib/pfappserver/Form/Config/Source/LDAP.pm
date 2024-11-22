package pfappserver::Form::Config::Source::LDAP;

=head1 NAME

pfappserver::Form::Config::Source::LDAP - Web form for a LDAP user source

=head1 DESCRIPTION

Form definition to create or update a LDAP user source.

=cut

BEGIN {
    use pf::Authentication::Source::LDAPSource;
}
use HTML::FormHandler::Moose;
extends 'pfappserver::Form::Config::Source';
with 'pfappserver::Base::Form::Role::Help', 'pfappserver::Base::Form::Role::InternalSource';

use pf::config qw(%Config);

our $META = pf::Authentication::Source::LDAPSource->meta;

has_field 'host' => (
    type => 'Repeatable',
    required => 1,
);

# Form fields
has_field 'host.contains' =>
  (
   type => 'Text',
   element_class => ['input-small'],
   element_attr => {'placeholder' => ''},
   required => 1,
  );
has_field 'port' =>
  (
   type => 'Port',
   element_class => ['input-mini'],
   element_attr => {'placeholder' => '389'},
   default => $META->get_attribute('port')->default,
  );
has_field 'dead_duration' =>
  (
    type         => 'PosInteger',
    element_attr => {
        'placeholder' => $META->get_attribute('dead_duration')->default
    },
    default => $META->get_attribute('dead_duration')->default,
  );
has_field 'connection_timeout' =>
  (
    type         => 'Float',
    element_attr => {
        'placeholder' => $META->get_attribute('connection_timeout')->default
    },
    default => $META->get_attribute('connection_timeout')->default,
    tags => { after_element => \&help,
             help => 'LDAP connection Timeout' },
  );
has_field 'write_timeout' =>
  (
    type         => 'Float',
    element_attr => {
        'placeholder' => $META->get_attribute('write_timeout')->default
    },
    default => $META->get_attribute('write_timeout')->default,
    tags => { after_element => \&help,
             help => 'LDAP request timeout' },
  );
has_field 'read_timeout' =>
  (
    type         => 'Float',
    element_attr => {
        'placeholder' => $META->get_attribute('read_timeout')->default
    },
    default => $META->get_attribute('read_timeout')->default,
    tags => { after_element => \&help,
             help => 'LDAP response timeout' },
  );
has_field 'encryption' =>
  (
   type => 'Select',
   options =>
   [
    { value => 'none', label => 'None' },
    { value => 'ssl', label => 'SSL' },
    { value => 'starttls', label => 'Start TLS' },
   ],
   required => 1,
   element_class => ['input-small'],
   default => 'none',
  );
has_field 'basedn' =>
  (
   type => 'Text',
   required => 1,
   # Default value needed for creating dummy source
   default => '',
   element_class => ['span10'],
  );
has_field 'scope' =>
  (
   type => 'Select',
   required => 1,
   options =>
   [
    { value => 'base', label => 'Base Object' },
    { value => 'one', label => 'One-level' },
    { value => 'sub', label => 'Subtree' },
    { value => 'children', label => 'Children' },
   ],
   default => 'sub',
  );
has_field 'usernameattribute' =>
  (
   type => 'Select',
   required => 1,
   options_method => \&options_attributes,
   element_class  => ['chzn-deselect', 'input-xxlarge'],
   element_attr   => { 'data-placeholder' => 'Click to select an attribute' },
   tags           => {
       after_element => \&help,
       help          => 'Main reference attribute that contain the username'
   },
   # Default value needed for creating dummy source
   default => '',
  );
has_field 'binddn' =>
  (
   type => 'Text',
   element_class => ['span10'],
   tags => { after_element => \&help,
             help => 'Leave this field empty if you want to perform an anonymous bind.' },
   # Default value needed for creating dummy source
   default => '',
  );
has_field 'password' =>
  (
   type => 'ObfuscatedText',
   trim => undef,
   # Default value needed for creating dummy source
   default => '',
  );
has_field 'cache_match',
  (
   type => 'Toggle',
   checkbox_value => '1',
   unchecked_value => '0',
   tags => { after_element => \&help,
             help => 'Will cache results of matching a rule' },
   default => $META->get_attribute('cache_match')->default,
  );

has_field 'email_attribute' => (
    type => 'Text',
    required => 0,
    default => $META->get_attribute('email_attribute')->default,
    tags => {
        after_element => \&help,
        help => 'LDAP attribute name that stores the email address against which the filter will match.',
    },
);

has_field 'monitor',
  (
   type => 'Toggle',
   checkbox_value => '1',
   unchecked_value => '0',
   tags => { after_element => \&help,
             help => 'Do you want to monitor this source?' },
   default => $META->get_attribute('monitor')->default,
);

has_field 'shuffle',
  (
   type => 'Toggle',
   checkbox_value => '1',
   unchecked_value => '0',
   tags => { after_element => \&help,
             help => 'Randomly choose LDAP server to query' },
   default => $META->get_attribute('shuffle')->default,
);

has_field 'use_connector',
  (
   type => 'Toggle',
   checkbox_value => '1',
   unchecked_value => '0',
   default => $META->get_attribute('use_connector')->default,
);

has_field 'searchattributes' => (
    type           => 'Select',
    multiple       => 1,
    options_method => \&options_attributes,
    element_class  => ['chzn-deselect', 'input-xxlarge'],
    element_attr   => { 'data-placeholder' => 'Click to select an attribute' },
    tags           => {
        after_element => \&help,
        help          => 'Other attributes that can be used as the username (requires to restart the radiusd service to be effective)'
    },
    default => '',
);

has_field 'append_to_searchattributes' => (
    type => 'Text',
    required => 0,
    default => '',
    tags => {
        after_element => \&help,
        help => 'Append this ldap filter to the generated generated ldap filter generated for the search attributes.',
    },
);

has_field verify => (
    type => 'Select',
    default => 'none',
    options => [
        map { { value => $_, label => $_ }  } qw(none optional require)
    ],
);

has_field client_cert_file => (
    type => 'Path',
    file_type => 'file',
    default => $META->get_attribute('client_cert_file')->default,
);

has_field 'client_cert_file_upload' => (
   type => 'PathUpload',
   accessor => 'client_cert_file',
   config_prefix => '.crt',
   required => 0,
   upload_namespace => 'sources',
);

has_field client_key_file => (
    type => 'Path',
    file_type => 'file',
    default => $META->get_attribute('client_key_file')->default,
);

has_field 'client_key_file_upload' => (
   type => 'PathUpload',
   accessor => 'client_key_file',
   config_prefix => '.key',
   required => 0,
   upload_namespace => 'sources',
);

has_field ca_file => (
    type => 'Path',
    file_type => 'file',
    default => $META->get_attribute('ca_file')->default,
);

has_field 'ca_file_upload' => (
   type => 'PathUpload',
   accessor => 'ca_file',
   config_prefix => '.crt',
   required => 0,
   upload_namespace => 'sources',
);

has '+dependency' => (
    default => sub {
        [
            [ 'client_cert_file', 'client_key_file' ]
        ];
    },
);

=head2 options_attributes

retrive the realms

=cut

sub options_attributes {
    my ($self) = @_;
    return map { $_ => $_} @{$Config{advanced}->{ldap_attributes}};
}

=head2 validate

Make sure a password is specified when a bind DN is specified.

=cut

sub validate {
    my $self = shift;

    $self->SUPER::validate();

    if ($self->value->{binddn}) {
        unless ($self->value->{password}) {
            $self->field('password')->add_error('Please specify a password.');
        }
    }
}

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
