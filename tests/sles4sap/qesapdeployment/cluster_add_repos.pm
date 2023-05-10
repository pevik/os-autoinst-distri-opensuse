# Copyright SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

# Summary: Deployment steps for qe-sap-deployment
# Maintainer: QE-SAP <qe-sap@suse.de>, Michele Pagot <michele.pagot@suse.com>

use strict;
use warnings;
use mmapi 'get_current_job_id';
use Mojo::Base 'publiccloud::basetest';
use testapi;
use qesapdeployment;

sub run() {
    my ($self, $run_args) = @_;
    my $instance = $run_args->{my_instance};
    record_info("$instance");
    set_var('MAINT_TEST_REPO', get_var('INCIDENT_REPO')) if get_var('INCIDENT_REPO');
    my $prov = get_required_var('PUBLIC_CLOUD_PROVIDER');

    my @repos = split(/,/, get_var('MAINT_TEST_REPO'));

    my $count = 0;

    while (defined(my $maintrepo = shift @repos)) {
        next if $maintrepo =~ /^\s*$/;
        qesap_ansible_cmd(cmd => "zypper --no-gpg-checks ar -f -n TEST_$count $maintrepo TEST_$count",
            provider => $prov);
        $count++;
    }

    qesap_ansible_cmd(cmd => 'sudo zypper -n ref', provider => $prov);
}

sub delete_peering {
    # destroy the network peering, if it was created
    my $rg = qesap_get_az_resource_group();
    my $vn = qesap_get_vnet($rg);
    my $target_rg = get_required_var('QESAP_TARGET_RESOURCE_GROUP');
    my $target_vn = qesap_get_vnet($target_rg);
    qesap_delete_az_peering(source_group => $rg, source_vnet => $vn, target_group => $target_rg, target_vnet => $target_vn);
}

sub test_flags {
    return {fatal => 1};
}

sub post_fail_hook {
    my ($self) = shift;
    qesap_upload_logs();

    delete_peering();

    my $inventory = qesap_get_inventory(get_required_var('PUBLIC_CLOUD_PROVIDER'));
    qesap_execute(cmd => 'ansible', cmd_options => '-d', verbose => 1, timeout => 300) unless (script_run("test -e $inventory"));
    qesap_execute(cmd => 'terraform', cmd_options => '-d', verbose => 1, timeout => 1200);
    $self->SUPER::post_fail_hook;
}

1;
