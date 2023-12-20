# SUSE's openQA tests
#
# Copyright SUSE LLC
# SPDX-License-Identifier: FSFAP

package rpi;

use warnings;
use strict;

use Exporter 'import';
use testapi;
use power_action_utils 'power_action';
use Utils::Backends;

our @EXPORT = 'enable_tpm_slb9670';

# Enable TPM on Raspberry Pi
# https://en.opensuse.org/HCL:Raspberry_Pi3_TPM
sub enable_tpm_slb9670 {
    my $module = "tpm_tis_spi";

    assert_script_run('echo -e "dtparam=spi=on\ndtoverlay=tpm-slb9670" >> /boot/efi/extraconfig.txt');
    assert_script_run('cat /boot/efi/extraconfig.txt');
    assert_script_run("echo '$module' > /etc/modules-load.d/tpm.conf");
    power_action('reboot', textmode => 1);

    # Add some timeout to wait for reboot
    sleep(60);

    # Restore SSH connection
    reset_consoles;

    bmwqemu::fctwarn("pev: is_generalhw: '" . is_generalhw . "', GENERAL_HW_VNC_IP: '". get_var('GENERAL_HW_VNC_IP', '') . "'"); # FIXME: debug
    #if (is_generalhw && !defined(get_var('GENERAL_HW_VNC_IP'))) {
    if (is_generalhw) {
        # Wait jeos-firstboot is done and clear screen, as we are already logged-in via ssh
        bmwqemu::fctwarn("pev: call wait_still_screen"); # FIXME: debug
        wait_still_screen;
        bmwqemu::fctwarn("pev: call clear_and_verify_console"); # FIXME: debug
        opensusebasetest::clear_and_verify_console;
    }

    select_console('root-ssh');

    record_info('RPi TPM', script_output("dmesg | grep '$module.*2.0 TPM.*device-id.*rev-id'"));
}

1;
