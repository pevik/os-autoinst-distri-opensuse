# SUSE's openQA tests
#
# Copyright © 2012-2016 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
#
# Summary: virt_autotest: the initial version of virtualization automation test in openqa, with kvm support fully, xen support not done yet
# Maintainer: alice <xlai@suse.com>

use strict;
use warnings;
use base "virt_autotest_base";
use testapi;
use virt_utils;
use utils;
use repo_tools 'add_qa_head_repo';
use Utils::Architectures 'is_s390x';

sub zypper_wrapper {
    my $cmd = shift;
    if (is_s390x) {
        lpar_cmd("zypper --non-interactive $cmd");
    } else {
        zypper_call($cmd);
    }
}

sub install_package {
    my $repo = 'qa_repo';
    zypper_wrapper("rr $repo");

    my $url = add_qa_head_repo(url_only => is_s390x);
    if (is_s390x) {
        zypper_wrapper("ar $url $repo");
        zypper_wrapper("--gpg-auto-import-keys ref --repo $repo");
    }

    # workaround for dependency on xmlstarlet for qa_lib_virtauto on sles11sp4 and sles12sp1
    # workaround for dependency on bridge-utils for qa_lib_virtauto on sles15sp0
    my $repo_0_to_install = get_var("REPO_0_TO_INSTALL", '');
    my $dependency_repo   = '';
    my $dependency_rpms   = '';
    if ($repo_0_to_install =~ /SLES-11-SP4/m) {
        $dependency_repo = 'http://download.suse.de/ibs/SUSE:/SLE-11:/Update/standard/';
        $dependency_rpms = 'xmlstarlet';
    }
    elsif ($repo_0_to_install =~ /SLE-12-SP1/m) {
        $dependency_repo = 'http://download.suse.de/ibs/SUSE:/SLE-12:/Update/standard/';
        $dependency_rpms = 'xmlstarlet';
    }
    elsif ($repo_0_to_install =~ /SLE-15-Installer/m) {
        $dependency_repo = 'http://download.suse.de/ibs/SUSE:/SLE-15:/GA/standard/';
        $dependency_rpms = 'bridge-utils';
    }

    if ($dependency_repo) {
        zypper_wrapper("--no-gpg-check ar -f $dependency_repo dependency_repo");
        zypper_wrapper("--gpg-auto-import-keys ref");
        zypper_wrapper("in $dependency_rpms");
        zypper_wrapper("rr dependency_repo");
    }

    ### SLE-12-SP4 arm64 installation has no KVM role selection
    if (($repo_0_to_install =~ /SLE-12-SP4/m) && check_var('ARCH', 'aarch64')) {
        zypper_call("--gpg-auto-import-keys ref",         180);
        zypper_call("in -t pattern kvm_server kvm_tools", 300);
    }

    zypper_wrapper("in qa_lib_virtauto");

    if (get_var("PROXY_MODE")) {
        if (get_var("XEN")) {
            zypper_call("in -t pattern xen_server", 1800);
        }
    }
}

sub run {
    install_package;
}


sub test_flags {
    return {fatal => 1};
}

1;

