# SUSE's openQA tests
#
# Copyright © 2021 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Configure and run fio utility. FIO_FILESIZE can be used to set
#          the size of generated file.
# Maintainer: QE Kernel <kernel-qa@suse.de>

use base "opensusebasetest";
use strict;
use warnings;
use testapi;
use utils;

sub run {
    my $self = shift;
    $self->select_serial_terminal;

    my $memory = get_var('FIO_FILESIZE', '256M');
    my $numcpu = get_required_var('QEMUCPUS');

    $testapi::distri->get_package_manager()->install_package("fio");
    assert_script_run("fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=test --filename=random_read_write --bs=4k --iodepth=64 --size=$memory --readwrite=randrw --rwmixread=75 --max-jobs=$numcpu");
}

1;
