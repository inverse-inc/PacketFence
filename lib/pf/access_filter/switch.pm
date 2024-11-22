package pf::access_filter::switch;

=head1 NAME

pf::access_filter::switch -

=head1 DESCRIPTION

pf::access_filter::switch

=cut

use strict;
use warnings;

use Scalar::Util qw(reftype);

use base qw(pf::access_filter);
tie our %ConfigSwitchFilters, 'pfconfig::cached_hash', 'config::SwitchFilters';
tie our %SwitchFilterEngineScopes, 'pfconfig::cached_hash', 'FilterEngine::SwitchScopes';
use List::MoreUtils qw(any);

=head2 filterRule

    Handle the switch update

=cut

sub filterRule {
    my ($self, $rule, $args) = @_;
    my $logger = $self->logger;
    my $switch_params = {};
    if(defined $rule) {
        if (defined($rule->{'switch'}) && $rule->{'switch'} ne '') {
            my $switch = $rule->{'switch'};
            return $switch;
        } elsif ( any { $_ eq 'radius_authorize' || $_ eq 'reevaluate' }  @{$rule->{'scopes'} // [] } ) {
            $logger->info(evalParam($rule->{'log'},$args)) if defined($rule->{'log'});
            for my $p (@{$rule->{params} // []}) {
                my @answer = $p =~ /([a-zA-Z_-]*)\s*=\s*(.*)/;
                evalAnswer(\@answer,$args,\$switch_params);
            }
            return ($switch_params);

        }
    }

    return undef;
}

=head2 evalAnswer

evaluate the radius answer

=cut

sub evalAnswer {
    my ($answer,$args,$switch_params) = @_;

    my $return = evalParam(@{$answer}[1],$args);
    my @multi_value = split(';',$return);
    @{$answer}[0] =~ s/\s//g;
    if (scalar @multi_value > 1) {
        $$switch_params->{'_'.@{$answer}[0]} = \@multi_value;
    } else {
        $$switch_params->{'_'.@{$answer}[0]} = $return;
    }

}

=head2 evalParam

evaluate all the variables

=cut

sub evalParam {
    my ($answer, $args) = @_;
    $answer =~ s/\$([a-zA-Z_0-9]+)/$args->{$1} \/\/ ''/ge;
    $answer =~ s/\$\{([a-zA-Z0-9_\-]+(?:\.[a-zA-Z0-9_\-]+)*)\}/&_replaceParamsDeep($1,$args)/ge;
    return $answer;
}

=head2 _replaceParamsDeep

evaluate all the variables deeply

=cut

sub _replaceParamsDeep {
    my ($param_string, $args) = @_;
    my @params = split /\./, $param_string;
    my $param  = pop @params;
    my $hash   = $args;
    foreach my $key (@params) {
        if (exists $hash->{$key} && reftype($hash->{$key}) eq 'HASH') {
            $hash = $hash->{$key};
            next;
        }
        return '';
    }
    return $hash->{$param} // '';
}

=head2 getEngineForScope

 gets the engine for the scope

=cut

sub getEngineForScope {
    my ($self, $scope) = @_;
    if (exists $SwitchFilterEngineScopes{$scope}) {
        return $SwitchFilterEngineScopes{$scope};
    }
    return undef;
}

=head2 filterSwitch

Filter the switch based off switch filters

=cut

sub filterSwitch {
    my $timer = pf::StatsD::Timer->new({ sample_rate => 1});
    my ($self, $scope, $switch, $args) = @_;
    my $switch_params = $self->filter($scope, $args);

    if (defined($switch_params)) {
        foreach my $key (keys %{$switch_params}) {
            if (ref($switch_params->{$key}) eq 'ARRAY') {
                foreach my $param (@{$switch_params->{$key}}) {
                    if ($param  =~ /([a-zA-Z_-]*)\s*=>\s*(.*)/) {
                        $$switch->{$key}->{$1} = $2;
                    }
                }
            } elsif ($switch_params->{$key} =~ /([a-zA-Z_-]*)\s*=>\s*(.*)/) {
                $$switch->{$key}->{$1} = $2;
            } else {
                $$switch->{$key} = $switch_params->{$key};
            }
        }
    }
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
