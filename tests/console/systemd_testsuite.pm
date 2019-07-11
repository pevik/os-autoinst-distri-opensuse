# SUSE's openQA tests
#
# Copyright © 2017 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Run testsuite included in systemd sources
# Maintainer: Sergio Lindo Mansilla <slindomansilla@suse.com>, Thomas Blume <tblume@suse.com>

use base "consoletest";
use warnings;
use strict;
use testapi;
use utils;
use repo_tools 'add_qa_head_repo';
use version_utils qw(is_leap is_tumbleweed is_sle);

sub run {
    # install systemd testsuite
    select_console 'root-console';
    add_qa_head_repo;
    zypper_call 'in systemd-qa-testsuite';

    # run the testsuite test scripts
    assert_script_run 'cd /var/opt/systemd-tests';
    assert_script_run './run-tests.sh --all 2>&1 | tee /tmp/testsuite.log', 6400;
    assert_script_run 'grep "# FAIL:  0" /tmp/testsuite.log';
    assert_script_run 'grep "# ERROR: 0" /tmp/testsuite.log';
}

sub post_fail_hook {
    my ($self) = shift;
    $self->SUPER::post_fail_hook;
    assert_script_run('cd /var/opt/systemd-tests/');
    assert_script_run('cp /tmp/testsuite.log logs/');
    assert_script_run('tar -cjf systemd-testsuite-logs.tar.bz2 logs/');
    upload_logs('systemd-testsuite-logs.tar.bz2');
    # Remove ANSI colors and filter failed tests
    my $failed_tests = script_output("sed --quiet 's/\x1b\[[0-9;]*m//g; /^FAIL:/p' /tmp/testsuite.log");
    for my $test_name ($failed_tests =~ /^FAIL: ([\w-]*)$/mg) {
        my $log_content = script_output("cat logs/$test_name-run.log");
        record_info("Failed test '$test_name'", "Failed test '$test_name' \n$log_content", result => 'fail');
    }
}


1;
