# SUSE's openQA tests
#
# Copyright 2023 SUSE LLC
# SPDX-License-Identifier: FSFAP
#
# Summary: Test switching virtio root-virtio-terminal and user-virtio-terminal.
# Maintainer: Petr Vorel <pvorel@suse.cz>

use Mojo::Base 'opensusebasetest';
use testapi;
use serial_terminal qw(select_serial_terminal select_user_serial_terminal);
use utils;

sub test_user {
    record_info('non-root user');
    select_user_serial_terminal;
    record_info('id non-root', script_output('id'));
    assert_script_run('[ $(id -u) = 1000 ]');
}

sub test_root {
    record_info('root user');
    select_serial_terminal;
    record_info('id root', script_output('id'));
    assert_script_run('[ $(id -u) = 0 ]');
}

sub run {
    record_info('getty', script_output('systemctl | grep serial-getty'));
    test_root;
    test_user;
    test_root;
    test_user;
}

1;

=head1 Configuration
See virtio_console.pm.

=cut
