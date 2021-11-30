# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright 2021 SUSE LLC
#
# Summary: Run selinux-testsuite with 'make test'.
# Maintainer: Petr Vorel <pvorel@suse.cz>

use 5.018;
use strict;
use warnings;
use base 'opensusebasetest';
use testapi;

sub run {
    my $self = shift;

    my $log = "make-test.txt";
    my $ret;

    record_info('make test');
    $ret = script_run("make test > $log 2>&1", timeout => 3600);
    record_info('LOG', script_output("cat $log"));
    upload_logs($log, failok => 1);

    if ($ret ne 0) {
        $self->{result} = 'fail';
    }

    autotest::loadtest("tests/shutdown/shutdown.pm");
}

1;

=head1 Summary

Run selinux-testsuite with 'make test'.

=head1 Configuration

See selinux_testsuite/install.pm.
