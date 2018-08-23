# SUSE's openQA tests
#
# Copyright © 2018 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Trying to stress kernel with fuzz testing using trinity
# Maintainer: Anton Smorodskyi<asmorodskyi@suse.com>

use base "opensusebasetest";
use testapi;
use utils;
use strict;
use serial_terminal 'select_virtio_console';
use upload_system_log;

sub run {
    my ($self) = @_;
    select_virtio_console();
    my $trinity     = 'trinity-1.8';
    my $trinity_log = script_output("echo ~$testapi::username/trinity.log");
    my $syscall_cnt = 1000000;
    my @grep_regex  = (
        "Oops:",
        "kernel BUG at",
        "Kernel BUG at",
        "WARNING: CPU",
        "stack-protector: Kernel stack is corrupted",
        "BUG: failure at",
        "\\-\\[ cut here \\]\\-");
    zypper_call('in gcc');
    assert_script_run("cd /");
    assert_script_run("wget --quiet " . data_url($trinity) . ".tar.xz -O $trinity.tar.xz");
    assert_script_run("tar xvf $trinity.tar.xz");
    assert_script_run('cd ./' . $trinity);
    assert_script_run('./configure; make', 600);
    assert_script_run('chmod -R 777 /' . $trinity);

    # assert_script_run("sudo -u $testapi::username ./trinity -N$syscall_cnt > $trinity_log", 2000);
    upload_system_logs();
=cut
    upload_logs($trinity_log);
    my $failures = 0;
    for my $regex (@grep_regex) {
        my $grep_out = script_output("grep \"$regex\" $trinity_log || true");
        if ($grep_out ne "") {
            record_info($regex, "Trinity log contain failures !");
            $failures = 1;
        }
    }
    die "Failure detected" if $failures;
=cut
}

1;
