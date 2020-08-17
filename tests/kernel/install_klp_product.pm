# SUSE's openQA tests
#
# Copyright © 2020 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
#
# Summary: This module installs the kernel livepatching product and
#          verifies the installation.
# Maintainer: Nicolai Stange <nstange@suse.de>

use 5.018;
use warnings;
use strict;
use base 'opensusebasetest';
use testapi;
use utils;
use klp;
use version_utils 'is_sle';
use power_action_utils 'power_action';

sub run {
    my $self = shift;
    my $kver;
    my $kflavor;

    my $use_serial = is_sle(">12-sp1") || !is_sle;
    $use_serial ? $self->select_serial_terminal() : select_console('root-console');

    my $output = script_output('uname -r');
    if ($output =~ /^([0-9]+([-.][0-9a-z]+)*)-([a-z][a-z0-9]*)/i) {
        $kver    = $1;
        $kflavor = $3;
    }
    else {
        die "Failed to parse 'uname -r' output: '$output'";
    }

    install_klp_product();
    my $klp_pkg = find_installed_klp_pkg($kver, $kflavor);
    if (!$klp_pkg) {
        die "No installed kernel livepatch package for current kernel found";
    }

    verify_klp_pkg_patch_is_active($klp_pkg);
    verify_klp_pkg_installation($klp_pkg);

    # Reboot and check that the livepatch gets loaded again.
    power_action('reboot', textmode => 1);
    $self->wait_boot;
    $use_serial ? $self->select_serial_terminal() : select_console('root-console');
    verify_klp_pkg_patch_is_active($klp_pkg);
}

sub test_flags {
    return {fatal => 1};
}

1;
