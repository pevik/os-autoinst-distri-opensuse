# SUSE's openQA tests
#
# Copyright © 2016-2018 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
#
# Summary: Waits for the guest to boot and sets some variables for LTP
# Maintainer: Richard Palethorpe <rpalethorpe@suse.com>

use 5.018;
use warnings;
use base 'opensusebasetest';
use testapi;
use bootloader_setup 'boot_grub_item';
use serial_terminal 'select_virtio_console';

sub run {
    my ($self, $tinfo) = @_;
    my $ltp_env    = get_var('LTP_ENV');
    my $cmd_file   = get_var('LTP_COMMAND_FILE') || '';
    my $is_network = $cmd_file =~ m/^\s*(net|net_stress)\./;
    my $is_ima     = $cmd_file =~ m/^ima$/i;

    if ($is_ima) {
        # boot kernel with IMA parameters
        $self->boot_grub_item();
    }
    else {
        # during install_ltp, the second boot may take longer than usual
        $self->wait_boot(ready_time => 500);
    }

    if (select_virtio_console()) {
        script_run('dmesg --console-level 7');
    }

    # DEBUG ONLY (DO NOT PUSH!)
    script_run('echo "===== START ====="');
    script_run('cat /proc/cmdline');

    script_run('echo "pev: test before" >/dev/kmsg');
    script_run('cat /sys/module/printk/parameters/time');
    script_run('echo 1 > /sys/module/printk/parameters/time');
    script_run('cat /sys/module/printk/parameters/time');
    script_run('echo "pev: test after" >/dev/kmsg');

    script_run('dmesg | grep -i tty');
    script_run('cat /proc/sys/kernel/printk');
    script_run('cat /proc/tty/driver/serial');
    script_run('cat /etc/securetty');
    script_run('cat /etc/ttytype');
    script_run('ls -1 /sys/class/tty/');
    script_run('grep GRUB_CMDLINE_LINUX /etc/default/grub');
    script_run('grep -i console /etc/default/grub');
    script_run('grep -e console= -e ttyS0 -e tty -r /etc');
    script_run('cat /etc/default/grub');
    script_run('systemctl |grep tty');
    script_run('systemctl |grep getty');
    script_run('dmesg > /tmp/dmesg.txt');
    upload_logs('/tmp/dmesg.txt', failok => 1);
    script_run('echo "===== END ====="');
}

sub test_flags {
    return {
        fatal     => 1,
        milestone => 1,
    };
}

1;

=head1 Configuration

See run_ltp.pm.

=cut
