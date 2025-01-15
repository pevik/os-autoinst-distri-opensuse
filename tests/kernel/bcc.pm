# Copyright 2023 SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

# Package: bpftrace
# Summary: Compile and attach eBPF probes with BCC tools
# Maintainer: kernel-qa@suse.de

use Mojo::Base qw(opensusebasetest);
use testapi;
use utils 'zypper_call';
use version_utils 'is_sle';
use serial_terminal 'select_serial_terminal';

sub run {
    select_serial_terminal;

    zypper_call('in bcc-tools');

    my $tools_dir = '/usr/share/bcc/tools';

    record_info('versions', script_output('rpm -qa |grep -i -e bcc', proceed_on_failure => 1));
    record_info('ldd', script_output('ldd $(command -v bcc)'));
    record_info('SONAME', script_output(q%for i in $(ldd $(command -v bcc) | awk '{print $3}'); do readelf -d $i | grep SONAME; done%));

    assert_script_run("$tools_dir/btrfsdist 5 2");
    assert_script_run("$tools_dir/btrfsslower -d 10");
    assert_script_run("$tools_dir/filetop -a 5 10");
}

sub test_flags {
    return {fatal => 0};
}

1;

=head1 Discussion

Smoke test for a small selection of BCC tools.
