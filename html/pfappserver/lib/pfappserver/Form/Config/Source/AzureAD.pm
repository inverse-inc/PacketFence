package pfappserver::Form::Config::Source::AzureAD;

=head1 NAME

pfappserver::Form::Config::Source::AzureAD - Web form for a AzureAD user source

=head1 DESCRIPTION

Form definition to create or update a AzureAD user source.

=cut

BEGIN {
    use pf::Authentication::Source::AzureADSource;
}
use HTML::FormHandler::Moose;
extends 'pfappserver::Form::Config::Source';
with 'pfappserver::Base::Form::Role::Help', 'pfappserver::Base::Form::Role::InternalSource';

use pf::config qw(%Config);

our $META = pf::Authentication::Source::AzureADSource->meta;

has_field 'client_id' =>
  (
   type => 'Text',
   required => 1,
   default => '',
  );

has_field 'client_secret' =>
  (
   type => 'Text',
   required => 1,
   default => '',
  );

has_field 'tenant_id' =>
  (
   type => 'Text',
   required => 1,
   default => '',
  );

has_field 'user_groups_url' =>
  (
   type => 'Text',
   required => 1,
    element_attr => {
        'placeholder' => $META->get_attribute('user_groups_url')->default
    },
    default => $META->get_attribute('user_groups_url')->default,
  );

has_field 'user_groups_cache' =>
  (
    type         => 'PosInteger',
    element_attr => {
        'placeholder' => $META->get_attribute('user_groups_cache')->default
    },
    default => $META->get_attribute('user_groups_cache')->default,
  );

has_field 'timeout' =>
  (
    type         => 'PosInteger',
    element_attr => {
        'placeholder' => $META->get_attribute('timeout')->default
    },
    default => $META->get_attribute('timeout')->default,
  );

=head1 COPYRIGHT

Copyright (C) 2005-2023 Inverse inc.

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
