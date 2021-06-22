package pfappserver::Form::Config::Provisioning::google_workspace_chromebook;

=head1 NAME

pfappserver::Form::Config::Provisioning - Web form for a switch

=head1 DESCRIPTION

=cut

use HTML::FormHandler::Moose;
extends 'pfappserver::Form::Config::Provisioning';
use pf::provisioner::google_workspace_chromebook;
our $META = pf::provisioner::google_workspace_chromebook->meta;

has_field host => (
    type => 'Text',
    default_method => \&default_field_method,
);

has_field port => (
    type => 'Text',
    default_method => \&default_field_method,
);

has_field protocol => (
    type => 'Text',
    default_method => \&default_field_method,
);

has_field service_account => (
    type => 'JSON',
    required => 1,
);

has_field customerId => (
    type => 'Text',
    default_method => \&default_field_method,
);

has_field user => (
    type => 'Text',
    required => 1,
);

has_field expires_in => (
    type => 'Integer',
    default_method => \&default_field_method,
);

has_field expires_jitter => (
    type => 'Integer',
    default_method => \&default_field_method,
);

sub default_field_method {
    my ($field) = @_;
    my $name = $field->name;
    my $attribute = $META->get_attribute($name)->default;
    if (ref($attribute) eq 'CODE') {
        return $attribute->();
    }

    return $attribute;
}

=head1 COPYRIGHT

Copyright (C) 2005-2021 Inverse inc.

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
