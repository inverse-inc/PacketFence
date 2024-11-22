package pfappserver::Form::Config::Source::SAML;

=head1 NAME

pfappserver::Form::Config::Source::SAML - Web form for a SAML user source

=head1 DESCRIPTION

Form definition to create or update a SAML user source.

=cut

use pf::authentication;
use HTML::FormHandler::Moose;
extends 'pfappserver::Form::Config::Source';
with qw(
    pfappserver::Base::Form::Role::Help
    pfappserver::Base::Form::Role::NoRules
);

# Form fields

has_field 'sp_entity_id' =>
  (
   type => 'Text',
   required => 1,
   default => '',
  );

has_field 'sp_key_path' => (
   type => 'Path',
   required => 0,
   default => '',
);

has_field 'sp_key_path_upload' => (
   type => 'PathUpload',
   accessor => 'sp_key_path',
   config_prefix => '.key',
   required => 0,
   upload_namespace => 'sources',
);

has_field 'sp_cert_path' => (
   type => 'Path',
   default => '',
   required => 0,
);

has_field 'sp_cert_path_upload' => (
   type => 'PathUpload',
   accessor => 'sp_cert_path',
   config_prefix => '.crt',
   required => 0,
   upload_namespace => 'sources',
);

has_field 'idp_entity_id' =>
  (
   type => 'Text',
   required => 1,
   default => '',
  );

has_field 'idp_metadata_path' => (
   type => 'Path',
   required => 0,
   default => '',
);

has_field 'idp_metadata_path_upload' => (
   type => 'PathUpload',
   accessor => 'idp_metadata_path',
   config_prefix => '.xml',
   required => 0,
   upload_namespace => 'sources',
);

has_field 'idp_cert_path' => (
   type => 'Path',
   required => 0,
   default => '',
);

has_field 'idp_cert_path_upload' => (
   type => 'PathUpload',
   accessor => 'idp_cert_path',
   config_prefix => '.crt',
   required => 0,
   upload_namespace => 'sources',
);

has_field 'idp_ca_cert_path' => (
   type => 'Path',
   required => 0,
   tags => { after_element => \&help,
             help => 'If your Identity Provider uses a self-signed certificate, put the path to its certificate here instead.' },
   default => '',
);

has_field 'idp_ca_cert_path_upload' => (
   type => 'PathUpload',
   accessor => 'idp_ca_cert_path',
   config_prefix => '.crt',
   required => 0,
   upload_namespace => 'sources',
);

has_field 'username_attribute' =>
  (
   type => 'Text',
    element_attr => {
        'placeholder' =>
            pf::Authentication::Source::SAMLSource->meta->get_attribute('username_attribute')->default
    },
    default => pf::Authentication::Source::SAMLSource->meta->get_attribute('username_attribute')->default,
  );

has_field 'authorization_source_id' =>
  (
   type => 'Select',
   multiple => 0,
   options_method => \&options_sources,
   element_class => ['chzn-deselect'],
   element_attr => {'data-placeholder' => 'Click to select a source'},
   tags => { after_element => \&help,
             help => 'The source to use for authorization (rule matching)' },
   required => 1,
   default => '',
  );


=head2 options_sources

Get the sources that can be used for authorization

=cut

sub options_sources {
    return map { ($_->type ne "SAML") ? ($_->id => $_->id) : () } @{pf::authentication::getInternalAuthenticationSources()};
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

