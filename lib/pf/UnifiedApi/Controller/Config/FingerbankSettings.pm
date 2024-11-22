package pf::UnifiedApi::Controller::Config::FingerbankSettings;

=head1 NAME

pf::UnifiedApi::Controller::Config::FingerbankSettings - 

=cut

=head1 DESCRIPTION

pf::UnifiedApi::Controller::Config::FingerbankSettings



=cut

use strict;
use warnings;


use Mojo::Base qw(pf::UnifiedApi::Controller::Config);

has 'config_store_class' => 'pf::ConfigStore::FingerbankSettings';
has 'form_class' => 'pfappserver::Form::Config::FingerbankSetting';
has 'primary_key' => 'fingerbank_setting_id';

use pf::ConfigStore::FingerbankSettings;
use pfappserver::Form::Config::FingerbankSetting;

sub form_parameters {
    my ($self, $item) = @_;
    my $name = $self->id // $item->{id};
    if (!defined $name) {
        return [];
    }
    return [section => $name];
}

sub cached_form {
    undef
}

=head2 fields_to_mask

fields_to_mask

=cut

sub fields_to_mask { qw(api_key password) }

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
