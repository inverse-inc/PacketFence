package pf::config::crypt::object;

=head1 NAME

pf::config::crypt::object -

=head1 DESCRIPTION

pf::config::crypt::object

=cut

use strict;
use warnings;
use pf::config::crypt;
use pf::config::crypt::string;

sub new {
    my ($proto, $data) = @_;
    my $class = ref($proto) || $proto;
    return bless(\$data, $class)
}

sub THAW {
    my ($class, $serializer, $data) = @_;
    if (rindex($data, $pf::config::crypt::PREFIX, 0) == 0) {
        $data = pf::config::crypt::pf_decrypt($data);
    }

    return pf::config::crypt::string->new($data);
}

sub TO_JSON {
    ${$_[0]}
}

use overload
    '""' => \&stringify,
    fallback => 1;


sub stringify {
    if (rindex(${$_[0]}, $pf::config::crypt::PREFIX, 0) == 0) {
        ${$_[0]} = pf::config::crypt::pf_decrypt(${$_[0]});
    }

    ${$_[0]}
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
