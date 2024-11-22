package pf::Authentication::Source::AuthorizationSource;

=head1 NAME

pf::Authentication::Source::AuthorizationSource

=cut

=head1 DESCRIPTION

pf::Authentication::Source::AuthorizationSource

=cut

use strict;
use warnings;
use Moose;
use pf::constants;
use pf::Authentication::constants;
use pf::config qw(%Config);
use List::Util qw(first);
use List::MoreUtils qw(uniq);

extends 'pf::Authentication::Source';
with qw(pf::Authentication::InternalRole);

has '+class' => (default => 'internal');
has '+type' => (default => 'Authorization');

=head2 available_attributes

Allow TLS Certificate attributes to be matched against

=cut

sub available_attributes {
    my ($self) = @_;
    my $super_attributes = $self->SUPER::available_attributes;
    my @own_attributes = map { {value => "radius_request.".$_, type => $Conditions::SUBSTRING}} qw(
      TLS-Client-Cert-Serial
      TLS-Client-Cert-Expiration
      TLS-Client-Cert-Issuer
      TLS-Client-Cert-Subject
      TLS-Client-Cert-Common-Name
      TLS-Client-Cert-Filename
      TLS-Client-Cert-Subject-Alt-Name-Email
      TLS-Client-Cert-X509v3-Extended-Key-Usage
      TLS-Cert-Serial
      TLS-Cert-Expiration
      TLS-Cert-Issuer
      TLS-Cert-Subject
      TLS-Cert-Common-Name
      TLS-Client-Cert-Subject-Alt-Name-Dns
    );
    my @attributes = @{$Config{radius_configuration}->{radius_attributes} // []};
    my @radius_attributes = map { { value => "radius_request.".$_, type => $Conditions::SUBSTRING } } @attributes;
    return [uniq(@$super_attributes, @own_attributes, @radius_attributes)];
}

=head2 available_actions

Only the authentication actions should be available

=cut

sub available_actions {
    my @actions = (map( { @$_ } $Actions::ACTIONS{$Rules::AUTH}), $Actions::SET_ACCESS_LEVEL);
    return \@actions;
}

=head2 match_in_subclass

=cut

sub match_in_subclass {
    my ($self, $params, $rule, $own_conditions, $matching_conditions) = @_;
    my $match = $rule->match;
    # If match any we just want the first
    my @conditions;
    if ($rule->match eq $Rules::ANY) {
        my $c = first { $self->match_condition($_, $params) } @$own_conditions;
        push @conditions, $c if $c;
    }
    else {
        @conditions = grep { $self->match_condition($_, $params) } @$own_conditions;
    }
    push @$matching_conditions, @conditions;
    return ($params->{'username'}, undef);
}

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

