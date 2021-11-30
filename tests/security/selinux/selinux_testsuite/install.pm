# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright 2021 SUSE LLC
#
# Summary: Install and run selinux-testsuite (with help of other modules)
# Maintainer: Petr Vorel <pvorel@suse.cz>

use 5.018;
use strict;
use warnings;
use base 'opensusebasetest';
use testapi;
use utils 'zypper_call';
use version_utils 'is_tumbleweed';

sub compile_testsuite {
    my $url = get_var('SELINUX_TESTSUITE_GIT_URL');

    if (!defined($url)) {
        if (is_tumbleweed) {
            $url = 'https://github.com/SELinuxProject/selinux-testsuite.git';
        } else {
            $url = 'http://gitlab.suse.de/suse-liberty-linux/selinux-testsuite.git';
            assert_script_run("git config --global http.sslVerify false");
        }
    }

    my $rel = get_var('SELINUX_TESTSUITE_RELEASE');
    my $dir = "selinux-testsuite";

    $rel = "-b $rel" if ($rel);

    my $ret = script_run("git clone -q --depth 1 $rel $url $dir && cd $dir", timeout => 360);
    if (!defined($ret) || $ret) {
        assert_script_run("git clone -q $rel $url $dir && cd $dir", timeout => 360);
    }

    record_info('git version', script_output('git log -1 --pretty=format:"git-%h" | tee'));

    record_info('make');
    assert_script_run('make -j$(getconf _NPROCESSORS_ONLN)');
}

sub install_dependencies {
    my @deps = qw(
      attr
      dosfstools
      e2fsprogs
      gcc
      git
      iptables
      kernel-devel
      keyutils-devel
      libselinux-devel
      libuuid-devel
      lksctp-tools-devel
      net-tools
      nftables
      perl-Test-Harness
      perl-Test-Simple
      policycoreutils-newrole
      quota
      xfsprogs-devel
    );

    zypper_call("in " . join(' ', @deps));

    my @maybe_deps = qw(
      kernel-default-extra
      libbpf-devel
      libselinux-devel
      selinux-policy-devel
    );
    for my $dep (@maybe_deps) {
        script_run('zypper -n -t in ' . $dep . ' | tee');
    }
}

sub upload_record_log {
    my ($title, $log) = @_;

    upload_logs($log, failok => 1);
    record_info($title, script_output("cat $log", proceed_on_failure => 1));
}

sub log_pkg {
    my $pkg = shift;
    my $title = "$pkg PKG";
    my $log = "$pkg.txt";

    script_run("rpm -qi $pkg > $log 2>&1");
    upload_record_log($title, $log);
}

sub log_cmd {
    my ($title, $cmd) = @_;
    my $log = lc("$title.txt");
    $log =~ s/\s+/-/g;

    script_run("$cmd > $log 2>&1");
    upload_record_log($title, $log);
}

sub log_pkgs {

    record_info('KERNEL VERSION', script_output('uname -a'));

    upload_record_log('KERNEL CONFIG', script_output('ls /boot/config-$(uname -r)'));

    for my $pkg (qw(kernel-default kernel-default-extra checkpolicy policycoreutils selinux-policy)) {
        log_pkg($pkg);
    }

    log_cmd('SELINUX PKG', 'rpm -qa | grep -i -e checkpolicy -e policycoreutils -e selinux');
}

sub run {
    my $self = shift;

    $self->select_serial_terminal;

    install_dependencies;
    log_pkgs;
    compile_testsuite;
}

sub test_flags {
    return {fatal => 1};
}

1;

=head1 Summary

Clone selinux-testsuite git, install it and run tests with help of other modules.

=head1 Configuration

=head2 SELINUX_TESTSUITE_GIT_URL

Overrides the official git repository URL.

=head2 SELINUX_TESTSUITE_RELEASE

When installing from Git this can be set to a release tag, commit hash, branch
name or whatever else Git will accept. Usually this is set to a release, such as
20160920, which will cause that release to be used. If not set, then the default
clone action will be performed, which probably means the latest master branch
will be used.

=head2 SELINUX_TESTSUITE_RUN

'prove' more debug info, nice rusults but can contains errors, because
for testing with 'prove' we need to reimplement setup from Makefile.

'make' run testing with 'make test' as expected by testsuite. It gets less
verbose info then when testing with 'prove', but can be used for debugging bugs
in openQA test.
