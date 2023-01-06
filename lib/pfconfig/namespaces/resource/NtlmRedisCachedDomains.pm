package pfconfig::namespaces::resource::NtlmRedisCachedDomains;

=head1 NAME

pfconfig::namespaces::resource::NtlmRedisCachedDomains -

=head1 DESCRIPTION

pfconfig::namespaces::resource::NtlmRedisCachedDomains

=cut

use strict;
use warnings;
use pfconfig::namespaces::config;
use pfconfig::namespaces::config::Domain;
use base 'pfconfig::namespaces::resource';
use pf::util qw(isenabled);

sub build {
    my ($self) = @_;
    my @domains;
    my $config = pfconfig::namespaces::config::Domain->new($self->{cache});
    my %DomainsConfig = %{ $config->build };
    while (my ($domain, $domain_info) = each %DomainsConfig) {
        push @domains, $domain if (isenabled($domain_info->{status}) && isenabled($domain_info->{ntlm_cache}) && isenabled($domain_info->{ntlm_cache_batch}));
    }

    return \@domains;
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

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

1;