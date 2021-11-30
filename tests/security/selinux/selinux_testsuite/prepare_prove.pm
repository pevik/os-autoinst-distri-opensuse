# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright 2021 SUSE LLC
#
# Summary: Prepare for running selinux-testsuite with 'prove'.
# Maintainer: Petr Vorel <pvorel@suse.cz>

use 5.018;
use strict;
use warnings;
use base 'opensusebasetest';
use testapi;
use File::Basename qw(basename dirname);

sub run {
    my $self = shift;

    record_info('LOADING TEST POLICY');
    assert_script_run('make -C policy load');

    assert_script_run('cd tests');

    record_info('make in tests');
    assert_script_run('make -j$(getconf _NPROCESSORS_ONLN) all');

    record_info('chcon');
    assert_script_run('chcon -R -t test_file_t .');

    my @tmp = (split(/\s+/, script_output('ls */test')));
    my %tests;
    $tests{$_}++ for (@tmp);

    # *probably* only for {fs_,}filesystems:
    # 1) remove parent test, e.g. {fs_,}filesystem/test
    # 2) add subtests e.g. {fs_,}filesystem/{ext4,xfs,..}/test
    for my $subtest (split(/\s+/, script_output('ls */*/test'))) {
        my $parent = dirname(dirname($subtest)) . "/test";
        if (exists $tests{$parent}) {
            bmwqemu::fctinfo("delete parent: '$parent'");
            delete $tests{$parent};
        }

        bmwqemu::fctinfo("add subtest: '$subtest'");
        $tests{$subtest} = '';
    }

    # only for {fs_,}filesystems:
    # 1) if filesystem, check with modprobe if supported
    for my $subtest (split(/\s+/, script_output('ls filesystem/*/test'))) {
        my $fs = basename(dirname($subtest));
        bmwqemu::fctinfo("modprobe $fs");
        if (script_run("modprobe $fs") != 0) {
            for my $dir (qw(filesystem fs_filesystem)) {
                my $key = "$dir/$fs/test";
                delete $tests{$key} if (exists $tests{$key});
            }
        }
    }

    my $count = scalar keys %tests;
    for my $test (sort keys %tests) {
        my $targs = OpenQA::Test::RunArgs->new();
        my $name = dirname($test);
        $name =~ s/\//_/g;
        $targs->{test} = $test;
        $targs->{name} = $name;
        $targs->{last} = !--$count;
        bmwqemu::fctinfo("schedule test: '$test', name: '$name'");
        autotest::loadtest("tests/security/selinux/selinux_testsuite/run_prove.pm", name => $name, run_args => $targs);
    }
}

sub test_flags {
    return {no_rollback => 1};
}

1;

=head1 Summary

Run selinux-testsuite with 'prove'.

=head1 Configuration

See selinux_testsuite/install.pm.
