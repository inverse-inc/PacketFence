package pfappserver::PacketFence::Controller::Node;

=head1 NAME

pfappserver::PacketFence::Controller::Node - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

use strict;
use warnings;

use HTTP::Status qw(:constants is_error is_success);
use Moose;
use namespace::autoclean;
use POSIX;

use pfappserver::Form::Node;
use pfappserver::Form::Node::Create::Import;

BEGIN { extends 'pfappserver::Base::Controller'; }
with 'pfappserver::Role::Controller::BulkActions';

__PACKAGE__->config(
    action => {
        bulk_close           => { AdminRole => 'NODES_UPDATE' },
        bulk_register        => { AdminRole => 'NODES_UPDATE' },
        bulk_deregister      => { AdminRole => 'NODES_UPDATE' },
        bulk_apply_role      => { AdminRole => 'NODES_UPDATE' },
        bulk_apply_violation => { AdminRole => 'NODES_UPDATE' },
        bulk_reevaluate_access => { AdminRole => 'NODES_UPDATE' },
    },
    action_args => {
        '*' => { model => 'Node' },
        'advanced_search' => { model => 'Search::Node', form => 'NodeSearch' },
        'simple_search' => { model => 'Search::Node', form => 'NodeSearch' },
        'search' => { model => 'Search::Node', form => 'NodeSearch' },
        'index' => { model => 'Search::Node', form => 'NodeSearch' },
    }
);

our %DEFAULT_COLUMNS = map { $_ => 1 } qw/status mac computername pid last_ip dhcp_fingerprint category online/;

=head1 SUBROUTINES


=head2 index

=cut

sub index :Path :Args(0) :AdminRole('NODES_READ') {
    my ( $self, $c ) = @_;
    $c->stash(template => 'node/search.tt', from_form => "#empty");
    $c->go('search');
}

=head2 search

Perform an advanced search using the Search::Node model

=cut

sub search :Local :Args() :AdminRole('NODES_READ') {
    my ($self, $c) = @_;
    my ($status, $status_msg, $result, $violations);
    my %search_results;
    my $model = $self->getModel($c);
    my $form = $self->getForm($c);
    my $request = $c->request();
    my $by = $request->param('by') || 'mac';
    my $direction = $request->param('direction') || 'asc';

    # Store columns in the session
    my $columns = $request->params->{'column'};
    if ($columns) {
        $columns = [$columns] if (ref($columns) ne 'ARRAY');
        my %columns_hash = map { $_ => 1 } @{$columns};
        my %params = ( 'nodecolumns' => \%columns_hash );
        $c->session(%params);
    }

    $form->process(params => $c->request->params);
    if ($form->has_errors) {
        $status = HTTP_BAD_REQUEST;
        $status_msg = $form->field_errors;
        $c->stash(current_view => 'JSON');
    }
    else {
        my $query = $form->value;
        $query->{by} = 'mac' unless ($query->{by});
        $query->{direction} = 'asc' unless ($query->{direction});
        ($status, $result) = $model->search($query);
        if (is_success($status)) {
            $c->stash(form => $form);
            $c->stash($result);
        }
    }

    (undef, $result) = $c->model('Roles')->list();
    (undef, $violations ) = $c->model('Config::Violations')->readAll();
    $c->stash(
        status_msg => $status_msg,
        roles => $result,
        violations => $violations,
        by => $by,
        direction => $direction,
    );
    unless ($c->session->{'nodecolumns'}) {
        # Set default visible columns
        $c->session( nodecolumns => \%DEFAULT_COLUMNS );
    }
    $c->stash->{switches} = $self->_get_switches_metadata($c);
    $c->stash->{search_action} = $c->action;
    $c->response->status($status);
}

=head2 simple_search

Perform an advanced search using the Search::Node model

=cut

sub simple_search :Local :Args() :AdminRole('NODES_READ') {
    my ($self, $c) = @_;
    $c->forward('search');
    $c->stash(template => 'node/search.tt', from_form => "#simpleNodeSearch");
}

=head2 advanced_search

Perform an advanced search using the Search::Node model

=cut

sub advanced_search :Local :Args() :AdminRole('NODES_READ') {
    my ($self, $c) = @_;
    $c->forward('search');
    $c->stash(template => 'node/search.tt', from_form => "#advancedSearch");
}

=head2 create

Create one node or import a CSV file.

=cut

sub create :Local : AdminRole('NODES_CREATE') {
    my ($self, $c) = @_;

    my ($roles, $node_status, $form_single, $form_import, $params, $type);
    my ($status, $result, $message);

    ($status, $result) = $c->model('Roles')->list();
    if (is_success($status)) {
        $roles = $result;
    }
    $node_status = $c->model('Node')->availableStatus();

    $form_single = pfappserver::Form::Node->new(ctx => $c, status => $node_status, roles => $roles);
    $form_import = pfappserver::Form::Node::Create::Import->new(ctx => $c, roles => $roles);

    if (scalar(keys %{$c->request->params}) > 1) {
        # We consider the request parameters only if we have at least two entries.
        # This is the result of setuping jQuery in "no Ajax cache" mode. See admin/common.js.
        $params = $c->request->params;
    } else {
        $params = {};
    }
    $form_single->process(params => $params);

    if ($c->request->method eq 'POST') {
        # Create new nodes
        $type = $c->request->param('type');
        if ($type eq 'single') {
            if ($form_single->has_errors) {
                $status = HTTP_BAD_REQUEST;
                $message = $form_single->field_errors;
            }
            else {
                ($status, $message) = $c->model('Node')->create($form_single->value);
            }
        }
        elsif ($type eq 'import') {
            my $params = $c->request->params;
            $params->{nodes_file} = $c->req->upload('nodes_file');
            $form_import->process(params => $params);
            if ($form_import->has_errors) {
                $status = HTTP_BAD_REQUEST;
                $message = $form_import->field_errors;
            }
            else {
                ($status, $message) = $c->model('Node')->importCSV($form_import->value, $c->user);
                if (is_success($status)) {
                    $message = $c->loc("[_1] nodes imported, [_2] skipped", $message->{count}, $message->{skipped});
                }
            }
        }
        else {
            $status = $STATUS::INTERNAL_SERVER_ERROR;
        }
        $self->audit_current_action($c, status => $status, create_type => $type);

        $c->response->status($status);
        $c->stash->{status} = $status;
        $c->stash->{status_msg} = $message; # TODO: localize error message
        $c->stash->{current_view} = 'JSON';
        # Since we are posting to an iframe if the content type is not plain text some browsers (IE 8/9) will try and download it
        $c->stash->{json_view_content_type} = 'text/plain';
    }
    else {
        # Initial display of the page
        $form_import->process();

        $c->stash->{form_single} = $form_single;
        $c->stash->{form_import} = $form_import;
    }
}

=head2 object

Node controller dispatcher

=cut

sub object :Chained('/') :PathPart('node') :CaptureArgs(1) {
    my ( $self, $c, $mac ) = @_;

    my ($status, $node_ref, $roles_ref);

    ($status, $node_ref) = $c->model('Node')->exists($mac);
    if ( is_error($status) ) {
        $c->response->status($status);
        $c->stash->{status_msg} = $node_ref;
        $c->stash->{current_view} = 'JSON';
        $c->detach();
    }
    ($status, $roles_ref) = $c->model('Roles')->list();
    if (is_success($status)) {
        $c->stash->{roles} = $roles_ref;
    }

    $c->stash->{mac} = $mac;
}

=head2 view

=cut

sub view :Chained('object') :PathPart('read') :Args(0) :AdminRole('NODES_READ') {
    my ($self, $c) = @_;

    my ($nodeStatus, $result);
    my ($form, $status);

    # Form initialization :
    # Retrieve node details and status

    ($status, $result) = $c->model('Node')->view($c->stash->{mac});
    if (is_success($status)) {
        $c->stash->{node} = $result;
    }
    $c->stash->{switches} = $self->_get_switches_metadata($c);
    $nodeStatus = $c->model('Node')->availableStatus();
    $form = $c->form("Node",
                     init_object => $c->stash->{node},
                     status => $nodeStatus,
                     roles => $c->stash->{roles}
    );
    $form->process();
    $c->stash->{form} = $form;

#    my @now = localtime;
#    $c->stash->{now} = { date => POSIX::strftime("%Y-%m-%d", @now),
#                         time => POSIX::strftime("%H:%M", @now) };
}

=head2 update

=cut

sub update :Chained('object') :PathPart('update') :Args(0) :AdminRole('NODES_UPDATE') {
    my ( $self, $c ) = @_;

    my ($status, $message);
    my ($form, $nodeStatus);

    $nodeStatus = $c->model('Node')->availableStatus();
    $form = $c->form("Node",
                     status => $nodeStatus,
                     roles => $c->stash->{roles}
    );
    $form->process(params => { mac => $c->stash->{mac}, %{$c->request->params} });
    if ($form->has_errors) {
        $status = HTTP_BAD_REQUEST;
        $message = $form->field_errors;
    }
    else {
        ($status, $message) = $c->model('Node')->update($c->stash->{mac}, $form->value);
        $self->audit_current_action($c, status => $status, mac => $c->stash->{mac});
    }
    if (is_error($status)) {
        $c->response->status($status);
        $c->stash->{status_msg} = $message; # TODO: localize error message
    }
    $c->stash->{current_view} = 'JSON';
}

=head2 delete

=cut

sub delete :Chained('object') :PathPart('delete') :Args(0) :AdminRole('NODES_DELETE') {
    my ( $self, $c ) = @_;

    my ($status, $message) = $c->model('Node')->delete($c->stash->{mac});
    $self->audit_current_action($c, status => $status, mac => $c->stash->{mac});
    if (is_error($status)) {
        $c->response->status($status);
        $c->stash->{status_msg} = $message; # TODO: localize error message
    }
    $c->stash->{current_view} = 'JSON';
}

=head2 reevaluate_access

Trigger the access reevaluation of the access of a node

=cut

sub reevaluate_access :Chained('object') :PathPart('reevaluate_access') :Args(0) :AdminRole('NODES_UPDATE') {
    my ( $self, $c ) = @_;

    my ($status, $message) = $c->model('Node')->reevaluate($c->stash->{mac});
    $self->audit_current_action($c, status => $status, mac => $c->stash->{mac});
    $c->response->status($status);
    $c->stash->{status_msg} = $message; # TODO: localize error message
    $c->stash->{current_view} = 'JSON';
}

=head2 wmiConfig

=cut

sub wmiConfig :Chained('object') :PathPart :Args(0) :AdminRole('NODES_READ'){
    my ($self, $c, $result) = @_;

    my $scan = pf::scan::wmi::rules->new();
    my $profile = pf::Portal::ProfileFactory->instantiate($result->{mac});
    my ($scan_exist, $scan_config) = $c->model('Config::Scan')->read($profile->{_scans});

    my $host = $result->{iplog}->{ip};
    
    foreach my $value ( keys %{$scan_config} ) {
        $scan_config->{'_' . $value} = $scan_config->{$value};
    }
 
    $scan_config->{_scanIp} = $host;
    return $scan, $scan_config, $scan_exist;
}

=head2 parseWmi

parsing answer

=cut

sub parseWmi {
    my ($self, $c, $scan, $scan_config) = @_;
    use Data::Dumper;
    my $rule_config = $c->model('Config::WMI')->readAll();
    $c->log->info(Dumper($rule_config));
    if ($rule_config->{prefix} eq 'tab') {
	my $config = $c->model('Config::WMI')->read($rule_config);
	my $scan_result = $scan->runWmi($scan_config, $config);
	if ($scan_result =~ /0x80041010/) {
	    $c->stash->{item_exist} = 'No';
	}elsif ($scan_result =~ /TIMEOUT/ || $scan_result =~ /UNREACHABLE/) {
	    $c->stash->{item_exist} = 'Request failed';
	}else {
	    $c->stash->{item_exist} = 'Yes';
	}
	return $scan_result;
    }
}

=head2 wmi

test 

=cut

sub wmi :Chained('object') :PathPart :Args(0) :AdminRole('NODES_READ') {
    my ($self, $c) = @_;

    my ($status, $result) = $c->model('Node')->view($c->stash->{mac});
    if (is_success($status)) {
        $c->stash->{node} = $result;
    }

    my ($scan, $scan_config, $scan_exist) = wmiConfig($self, $c, $result);

    my $config_sccm = $c->model('Config::WMI')->read('SCCM');
    my $config_antivirus = $c->model('Config::WMI')->read('Antivirus');
    my $config_firewall = $c->model('Config::WMI')->read('FireWall');
    my $config_antispyware = $c->model('Config::WMI')->read('AntiSpyware');

    if (is_success($scan_exist)) {
        my $result_sccm = $scan->runWmi($scan_config, $config_sccm);
        my $result_antivirus = $scan->runWmi($scan_config, $config_antivirus);
        my $result_firewall = $scan->runWmi($scan_config, $config_firewall);
        my $result_antispyware = $scan->runWmi($scan_config, $config_antispyware);

        if ($result_sccm =~ /0x80041010/) {
            $c->stash->{sccm_scan} = 'No';
        }elsif ($result_sccm =~ /TIMEOUT/ || $result_sccm =~ /UNREACHABLE/) {
            $c->stash->{sccm_scan} = 'Request failed';
        }else {
            $c->stash->{sccm_scan} = 'Yes';
        }
        if ($result_antivirus =~ /0x80041010/) {
            $c->stash->{antivirus_scan} = 'No';
        }elsif ($result_antivirus =~ /TIMEOUT/ || $result_antivirus =~ /UNREACHABLE/) {
            $c->stash->{antivirus_scan} = 'Request failed';
        }else {
            my $antivirus_res = $result_antivirus->[0];
            $c->stash->{antivirus_scan} = 'Yes';
            $c->stash->{antivirus_name} = $antivirus_res->{'displayName'};
            $c->stash->{antivirus_version} = $antivirus_res->{'productState'};
        }
        if ($result_firewall =~ /0x80041010/) {
            $c->stash->{firewall_scan} = 'No';
        }elsif ($result_firewall =~ /TIMEOUT/ || $result_firewall =~ /UNREACHABLE/) {
            $c->stash->{firewall_scan} = 'Request failed';
        }else {
            my $firewall_res = $result_firewall->[0];
            $c->stash->{firewall_scan} = 'Yes';
            $c->stash->{firewall_name} = $firewall_res->{'displayName'};
            $c->stash->{firewall_version} = $firewall_res->{'productState'};
        }
        if ($result_antispyware =~ /0x80041010/) {
            $c->stash->{antispyware_scan} = 'No';
        }elsif ($result_antispyware =~ /TIMEOUT/ || $result_antispyware =~ /UNREACHABLE/) {
            $c->stash->{antispyware_scan} = 'Request failed';
        }else {
            my $antispyware_res = $result_antispyware->[0];
            $c->stash->{antispyware_scan} = 'Yes';
            $c->stash->{antispyware_name} = $antispyware_res->{'displayName'};
            $c->stash->{antispyware_version} = $antispyware_res->{'productState'};
        }
    }
    else {
        $c->response->status($scan_exist);
        $c->stash->{status_msg} = $scan_config;
        $c->stash->{current_view} = 'JSON';
    }
}

=head2 scanProcess

=cut

sub scanProcess :Chained('object') :PathPart :Args(0) :AdminRole('NODES_READ') {
    my ($self, $c) = @_;

    my ($status, $result) = $c->model('Node')->view($c->stash->{mac});

    my ($scan, $scan_config) = wmiConfig($self, $c, $result);

    my $config_process = $c->model('Config::WMI')->read('Process_Running');
    my $result_process = $scan->runWmi($scan_config, $config_process);
    if ($result_process =~ /0x80041010/) {
        $c->stash->{running_process} = 'No';
    }elsif ($result_process =~ /TIMEOUT/ || $result_process =~ /UNREACHABLE/) {
        $c->stash->{running_process} = 'Request failed';
    }else {
        $c->stash->{running_process} = $result_process;
    }
}

=head2 violations

=cut

sub violations :Chained('object') :PathPart :Args(0) :AdminRole('NODES_READ') {
    my ($self, $c) = @_;
    my ($status, $result) = $c->model('Node')->violations($c->stash->{mac});
    if (is_success($status)) {
        $c->stash->{items} = $result;
        (undef, $result) = $c->model('Config::Violations')->readAll();
        my @violations = grep { $_->{id} ne 'defaults' } @$result; # remove defaults
        $c->stash->{violations} = \@violations;
    }
    else {
        $c->response->status($status);
        $c->stash->{status_msg} = $result;
        $c->stash->{current_view} = 'JSON';
    }
}

=head2 triggerViolation

=cut

sub triggerViolation :Chained('object') :PathPart('trigger') :Args(1) :AdminRole('NODES_UPDATE') {
    my ($self, $c, $id) = @_;
    my ($status, $result) = $c->model('Config::Violations')->hasId($id);
    if (is_success($status)) {
        ($status, $result) = $c->model('Node')->addViolation($c->stash->{mac}, $id);
        $self->audit_current_action($c, status => $status, mac => $c->stash->{mac}, violation_id => $id);
    }
    $c->response->status($status);
    $c->stash->{status_msg} = $result;
    if (is_success($status)) {
        $c->forward('violations');
    }
    else {
        $c->stash->{current_view} = 'JSON';
    }
}

=head2 closeViolation

=cut

sub closeViolation :Path('close') :Args(1) :AdminRole('NODES_UPDATE') {
    my ($self, $c, $id) = @_;
    my ($status, $result) = $c->model('Node')->closeViolation($id);
    $self->audit_current_action($c, status => $status, mac => $id);
    $c->response->status($status);
    $c->stash->{status_msg} = $result;
    $c->stash->{current_view} = 'JSON';
}

=head2 runViolation

=cut

sub runViolation :Path('run') :Args(1) :AdminRole('NODES_UPDATE') {
    my ($self, $c, $id) = @_;
    my ($status, $result) = $c->model('Node')->runViolation($id);
    $self->audit_current_action($c, status => $status, mac => $id);
    $c->response->status($status);
    $c->stash->{status_msg} = $result;
    $c->stash->{current_view} = 'JSON';
}

=head2 bulk_apply_bypass_role

=cut

sub bulk_apply_bypass_role : Local : Args(1) :AdminRole('NODES_UPDATE') {
    my ( $self, $c, $role ) = @_;
    $c->stash->{current_view} = 'JSON';
    my ( $status, $status_msg );
    my $request = $c->request;
    if ($request->method eq 'POST') {
        my @ids = $request->param('items');
        ($status, $status_msg) = $self->getModel($c)->bulkApplyBypassRole($role,@ids);
        $self->audit_current_action($c, status => $status, macs => \@ids);
    }
    else {
        $status = HTTP_BAD_REQUEST;
        $status_msg = "";
    }
    $c->response->status($status);
    $c->stash->{status_msg} = $status_msg;
}

sub _get_switches_metadata : Private {
    my ($self,$c) = @_;
    my ($status, $result) = $c->model('Config::Switch')->readAll();
    if (is_success($status)) {
        my %switches = map { $_->{id} => { type => $_->{type},
                                           mode => $_->{mode},
                                           description => $_->{description} } } @$result;
        return \%switches;
    }
    return undef;
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2016 Inverse inc.

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

__PACKAGE__->meta->make_immutable;

1;
