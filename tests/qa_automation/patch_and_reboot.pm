# SUSE's openQA tests
#
# Copyright © 2016-2019 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
#

# inherit qa_run, but overwrite run
# Summary: QA Automation: patch the system before running the test
#          This is to test Test Updates
# Maintainer: Stephan Kulow <coolo@suse.de>

use base "opensusebasetest";
use strict;
use warnings;
use utils;
use testapi;
use qam;

sub run {
    my $self = shift;

    set_var('VIRTIO_CONSOLE', 0);
    bmwqemu::save_vars();
    $self->select_serial_terminal;

    pkcon_quit unless check_var('DESKTOP', 'textmode');

    zypper_call(q{mr -d $(zypper lr | awk -F '|' '/NVIDIA/ {print $3}')}, exitcode => [0, 3]);

    add_test_repositories;

    fully_patch_system;

    console('root-ssh')->kill_ssh if check_var('BACKEND', 'ipmi');
    type_string "reboot\n";

    $self->wait_boot;
}

sub test_flags {
    return {fatal => 1};
}

1;
