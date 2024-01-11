#!/usr/bin/perl

use strict;
use warnings;

use lib qw(/usr/local/pf/lib /usr/local/pf/lib_perl/lib/perl5);
use pf::file_paths qw($install_dir);
use pf::services;
use File::Find;
use File::Slurp qw(read_file write_file);
use Data::Dumper;
use JSON::MaybeXS qw();
use YAML::XS qw(:all);
use JSON::PP qw();
use Hash::Merge qw(merge);
$YAML::XS::Boolean = "JSON::PP";
my $base_path = "$install_dir/docs/api/spec";

my $spec = LoadFile("$base_path/openapi-base.yaml");

merge_yaml_into_paths($spec->{paths}, "paths");
merge_yaml_into_paths($spec->{paths}, "deprecated/paths");
merge_yaml_into_paths($spec->{paths}, "static/paths");

my $components = hash_yaml_dir("components");
my $components_deprecated = hash_yaml_dir("deprecated/components");
my $components_static = hash_yaml_dir("static/components");
$spec->{components} = merge($components, $components_static, $components_deprecated);

common_parameters(
    $spec,
    {
        'required' => 0,
        'in'       => 'header',
        'name'     => 'X-PacketFence-Tenant-Id',
        'schema'   => {
            'type' => 'string'
        },
        'description' =>
'The tenant ID to use for this request. Can only be used if the API user has access to other tenants. When empty, it will default to use the tenant attached to the token.'
    }
);

insert_search_parameters($spec);

# insert service paramters
$spec->{components}->{parameters}->{service} = {
  name => 'service',
  in => 'path',
  required =>  JSON::MaybeXS::true,
  description => 'Service unique identifier.',
  schema => {
    type => 'string',
    enum => [ map {$_->name} grep { $_->name ne 'pf' } @pf::services::ALL_MANAGERS ],
  },
};

YAML::XS::DumpFile("$base_path/openapi.yaml", $spec);

write_file("$base_path/openapi.json", JSON::MaybeXS->new->pretty(1)->canonical(1)->encode($spec));

sub dir_yaml_files {
    my ($dir) = @_;
    my @files;
    find({ wanted => sub { push @files, $_ if $_ =~ /\.yaml$/ }, follow => 1, no_chdir => 1}, "$base_path/$dir");
    return sort @files;
}

my %HTTP_METHODS = (
    map { $_ => 1 } qw(get post head patch delete options put patch)
);

sub common_parameters {
    my ($yaml_spec, @parameters) = @_;
    for my $path (values %{$yaml_spec->{paths}}) {
        while ( my ($k, $method) = each %$path) {
            next if !exists $HTTP_METHODS{lc($k)};
            push @{$method->{parameters}}, @parameters;
        }
    }
}

sub insert_search_parameters {
    my ($yaml_spec) = @_;
    while ( my ( $name, $path ) = each %{ $yaml_spec->{paths} } ) {
        next if $name !~ m#/search#;
        while ( my ($k, $method) = each %$path) {
            next if !exists $HTTP_METHODS{lc($k)};
            push @{ $method->{parameters} },
              { '$ref' => "#/components/parameters/cursor" },
              { '$ref' => "#/components/parameters/limit" },
              { '$ref' => "#/components/parameters/search_query" },
              { '$ref' => "#/components/parameters/fields" },
              { '$ref' => "#/components/parameters/sort" };
        }
    }
}

sub hash_yaml_dir {
    my ($dir) = @_;
    my %all;
    my $full_path = "$base_path/$dir";
    for my $file (dir_yaml_files($dir)) {
        my $path_parts = $file;
        $path_parts =~ s#\Q$full_path\E/##;
        my @parts = split ('/', $path_parts);
        my $object = LoadFile($file);
        my $root = \%all;
        pop @parts;
        for my $part (@parts) {
            $root = $root->{$part} //= {};
        }
        %$root = (%$root, %$object);
    }
    return \%all;
}


sub merge_yaml_into_paths {
    my ($component, $path) = @_;
    my @files = dir_yaml_files($path);
    for my $file (@files) {
        my $object = eval{ LoadFile($file) };
        if ($@) {
            die "$file : $@\n"
        }
        while (my ($k, $v) = each %$object) {
            $component->{$k} = $v;
        }
    }
}

