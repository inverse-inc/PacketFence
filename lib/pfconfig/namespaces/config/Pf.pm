package pfconfig::namespaces::config::Pf;

=head1 NAME

pfconfig::namespaces::config::Pf

=cut

=head1 DESCRIPTION

pfconfig::namespaces::config::Pf

This module creates the configuration hash associated to pf.conf

=cut


use strict;
use warnings;

use pfconfig::namespaces::config;
use Config::IniFiles;
use Data::Dumper;
use pfconfig::log;
use pf::file_paths;
#use pf::util;
use JSON;

use base 'pfconfig::namespaces::config';

# need to override it since it imports data from pf.conf.defaults
sub build {
  my ($self) = @_;

  my %tmp_cfg;

  my $pf_conf_defaults = Config::IniFiles->new(-file => $pf_default_file);

  tie %tmp_cfg, 'Config::IniFiles', ( -file => $self->{file}, -import => $pf_conf_defaults);

  # for pfcmd checkup
  $self->{_file_cfg} = { %tmp_cfg };

  my $json = encode_json(\%tmp_cfg);
  my $cfg = decode_json($json);

  $self->unarray_parameters($cfg);

  $self->{cfg} = $cfg;

  my $child_resource = $self->build_child();
  return $child_resource;
}

sub init {
  my ($self) = @_;
  $self->{file} = $pf_config_file;
  $self->{default_config} = $self->{cache}->get_cache('config::PfDefault');
  $self->{doc_config} = $self->{cache}->get_cache('config::Documentation');
  $self->{child_resources} = [
    'resource::CaptivePortal',
    'resource::Database',
  ]; 
}

sub build_child {
    my ($self) = @_;

    my %Config = %{$self->{cfg}}; 
    my %Doc_Config = %{$self->{doc_config}};
    my %Default_Config = %{$self->{default_config}};

    my @time_values = grep { my $t = $Doc_Config{$_}{type}; defined $t && $t eq 'time' } keys %Doc_Config;

    # normalize time
    foreach my $val (@time_values ) {
        my ( $group, $item ) = split( /\./, $val );
        $Config{$group}{$item} = $self->normalize_time($Config{$group}{$item}) if ($Config{$group}{$item});
    }

    # determine absolute paths
    foreach my $val ("alerting.log") {
        my ( $group, $item ) = split( /\./, $val );
        if ( !File::Spec->file_name_is_absolute( $Config{$group}{$item} ) ) {
            $Config{$group}{$item} = File::Spec->catfile( $log_dir, $Config{$group}{$item} );
        }
    }

    #CREATE RESOURCE
    #$fqdn = sprintf("%s.%s",
    #                $Config{'general'}{'hostname'} || $Default_Config{'general'}{'hostname'},
    #                $Config{'general'}{'domain'} || $Default_Config{'general'}{'domain'});

    $Config{trapping}{passthroughs} = [split(/\s*,\s*/,$Config{trapping}{passthroughs} || '') ];
    if ($self->isenabled($Config{'trapping'}{'passthrough'})) {
        $Config{trapping}{proxy_passthroughs} = [
            split(/\s*,\s*/,$Config{trapping}{proxy_passthroughs} || ''),
            qw(
                crl.geotrust.com ocsp.geotrust.com crl.thawte.com ocsp.thawte.com
                crl.comodoca.com ocsp.comodoca.com crl.incommon.org ocsp.incommon.org
                crl.usertrust.com ocsp.usertrust.com mscrl.microsoft.com crl.microsoft.com
                ocsp.apple.com ocsp.digicert.com ocsp.entrust.com srvintl-crl.verisign.com
                ocsp.verisign.com ctldl.windowsupdate.com crl.globalsign.net pki.google.com
                www.microsoft.com crl.godaddy.com ocsp.godaddy.com certificates.godaddy.com
            )
        ];
    } else {
        $Config{trapping}{proxy_passthroughs} = [
            qw(
                crl.geotrust.com ocsp.geotrust.com crl.thawte.com ocsp.thawte.com
                crl.comodoca.com ocsp.comodoca.com crl.incommon.org ocsp.incommon.org
                crl.usertrust.com ocsp.usertrust.com mscrl.microsoft.com crl.microsoft.com
                ocsp.apple.com ocsp.digicert.com ocsp.entrust.com srvintl-crl.verisign.com
                ocsp.verisign.com ctldl.windowsupdate.com crl.globalsign.net pki.google.com
                www.microsoft.com crl.godaddy.com ocsp.godaddy.com certificates.godaddy.com
            )
        ];
    }
    $Config{network}{dhcp_filter_by_message_types} = [split(/\s*,\s*/,$Config{network}{dhcp_filter_by_message_types} || '')],

  
    $self->{cfg} = \%Config;

    return \%Config;

}


=back

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2015 Inverse inc.

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

# vim: set shiftwidth=4:
# vim: set expandtab:
# vim: set backspace=indent,eol,start:

