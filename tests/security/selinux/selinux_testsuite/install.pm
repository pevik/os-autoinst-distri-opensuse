# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright 2021 SUSE LLC
#
# Summary: Install and run selinux-testsuite (with help of other modules)
# Maintainer: Petr Vorel <pvorel@suse.cz>

use 5.018;
use base 'selinuxtest';
use strict;
use warnings;
use testapi;
use bootloader_setup 'add_grub_cmdline_settings';
use power_action_utils 'power_action';
use utils 'zypper_call';
use Utils::Architectures;
use version_utils 'is_tumbleweed';

use constant SELINUX_TESTSUITE_DIR => '~/selinux-testsuite';

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
    my $timeout = (is_aarch64 || is_s390x) ? 7200 : 1440;

    $rel = "-b $rel" if ($rel);

    my $cmd1 = "git clone -q $rel $url " . SELINUX_TESTSUITE_DIR;
    my $cmd2 = "cd " . SELINUX_TESTSUITE_DIR;
    my $ret = script_run("$cmd1 --depth 1 && $cmd2", timeout => 360);
    if (!defined($ret) || $ret) {
        assert_script_run("$cmd1 && $cmd2", timeout => 360);
    }

    record_info('git version', script_output('git log -1 --pretty=format:"git-%h" | tee'));
    upload_record_log('sctp_common.c', 'tests/sctp/sctp_common.c');    # FIXME: debug

    record_info('make');
    assert_script_run('make -j$(getconf _NPROCESSORS_ONLN)', timeout => $timeout);
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
      linux-glibc-devel
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
    record_info('cmdline', script_output('cat /proc/cmdline'));

    upload_record_log('KERNEL CONFIG', script_output('ls /boot/config-$(uname -r)'));

    for my $pkg (qw(checkpolicy kernel-default kernel-default-extra linux-glibc-devel policycoreutils selinux-policy)) {
        log_pkg($pkg);
    }

    log_cmd('SELINUX PKG', 'rpm -qa | grep -i -e checkpolicy -e policycoreutils -e selinux');
}

# NOTE: need to be run after each boot
sub unblacklist_jfs {
    # workaround for /usr/lib/module-init-tools/unblacklist
    # unblacklist: Do you want to un-blacklist jfs permanently (<y>es/<n>o/n<e>ver)
    script_run('yes | modprobe -f jfs');
}

sub run {
    my $self = shift;

    $self->select_serial_terminal;
    unblacklist_jfs;

    install_dependencies;

    # FIXME: debug
    script_run('grep SCTP_STREAM_RESET_EVENT /usr/include/linux/sctp.h');
    script_run('grep SCTP_STREAM_RESET_EVENT /usr/include/netinet/sctp.h');
    upload_record_log('linux-sctp.h', '/usr/include/linux/sctp.h');
    upload_record_log('netinet-sctp.h', '/usr/include/netinet/sctp.h');
    script_run('ls -la /usr/share/selinux/devel/include/kernel/corenetwork.if /sys/fs/selinux/policy_capabilities/extended_socket_class');
    # FIXME: debug

    log_pkgs;
    compile_testsuite;

    # 'minimum' was problematic, thus use 'targeted'
    # General policy load
    # /usr/sbin/semodule -i test_policy/test_policy.pp ...
    # Failed to resolve typeattributeset statement at /var/lib/selinux/minimum/tmp/modules/400/test_policy/cil:1280
    # Failed to resolve AST
    # /usr/sbin/semodule:  Failed!
    $self->set_sestatus('permissive', 'targeted');

    unblacklist_jfs;
    script_run("cd " . SELINUX_TESTSUITE_DIR);
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
