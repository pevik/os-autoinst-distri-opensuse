# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright 2021 SUSE LLC
#
# Summary: Run single selinux-testsuite test with 'prove'
# Maintainer: Petr Vorel <pvorel@suse.cz>

use 5.018;
use strict;
use warnings;
use base 'opensusebasetest';
use testapi;
use File::Basename 'dirname';

sub run {
    my ($self, $args) = @_;
    my $result;

    bmwqemu::fctinfo("test: '$args->{test}'");
    die 'missing test' unless defined $args->{test};

    my $log = "\$PWD/$args->{name}.txt";
    my $cmd = "prove --nocolor -v $args->{test} > $log 2>&1";
    record_info('CMD', $cmd);

    script_run("echo 'OpenQA::security/selinux/selinux_testsuite/run_prove.pm: Starting $args->{test} ($cmd)' > /dev/$serialdev");
    my $ret = script_run($cmd, timeout => 360);
    bmwqemu::fctinfo("ret: '$ret'");

    record_info('LOG', script_output("cat $log"));

    $result = script_output('grep "^Result: [A-Z]\+$" ' . $log);
    bmwqemu::fctinfo("result: '$result'");
    $result =~ s/^Result: ([A-Z]+)$/$1/;

    upload_logs($log, failok => 1);

    if (not defined $result || $result eq '') {
        die "Empty result: '$result'\n";
    }

    if ($ret ne 0) {
        $self->{result} = 'fail';
    } elsif ($result eq 'FAIL' && $ret eq 0) {
        record_info("WARNING", "Failed test returned 0");
        $self->{result} = 'fail';
    } elsif ($result eq 'NOTESTS') {
        $self->{result} = 'skip';
    } elsif ($result ne 'PASS') {
        die "Unknown result: '$result'\n";
    }

    if ($args->{last}) {
        autotest::loadtest("tests/shutdown/shutdown.pm");
    }
}

sub test_flags {
    return {no_rollback => 1};
}

1;

=head1 Summary

Module called dynamically by security/selinux/selinux_testsuite/prepare_prove.pm
intended for better test result representation (inspred by LTP).

=head1 Configuration

See security/selinux/selinux_testsuite/install.pm.
