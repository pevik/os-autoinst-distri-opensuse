# Copyright (C) 2014-2017 SUSE LLC
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, see <http://www.gnu.org/licenses/>.
# Summary: performing extra actions specific to sle 15 which are not available normally
# - If sle15+, switch to text console (ctrl-alt-f2)
# - If system still in graphic, record failure
# - Stop packagekit service
# Maintainer: Rodion Iafarov <riafarov@suse.com>

use base qw(consoletest distribution);
use strict;
use warnings;
use testapi;
use utils qw(zypper_call pkcon_quit);
use version_utils 'is_sle';

sub run {
    my $self = shift;
    return unless is_sle('15+');
    # try to detect bsc#1054782 only on the backend which can handle
    # 'ctrl-alt-f2' directly
    if (check_var('BACKEND', 'qemu')) {
        send_key('ctrl-alt-f2');
        assert_screen(["tty2-selected", 'text-login', 'text-logged-in-root', 'generic-desktop']);
        if (match_has_tag 'generic-desktop') {
            record_soft_failure 'bsc#1054782';
        }
    }

    $self->select_serial_terminal;

    # Stop packagekit
    pkcon_quit;

    # poo#60245, bsc#1157896 (originally poo#18762): workaround for missing NIC configuration.
    my $conf_nic_script = << 'EOF';
dir=/sys/class/net
ifaces="`basename -a $dir/* | grep -v -e ^lo -e ^tun -e ^virbr -e ^vnet`"
CREATED_NIC=
for iface in $ifaces; do
    config=/etc/sysconfig/network/ifcfg-$iface
    if [ "`cat $dir/$iface/operstate`" = "down" ] && [ ! -e $config ]; then
        echo "WARNING: create config '$config'" >&2
        printf "BOOTPROTO='dhcp'\nSTARTMODE='auto'\nDHCLIENT_SET_DEFAULT_ROUTE='yes'\n" > $config
        CREATED_NIC="$CREATED_NIC $iface"
        systemctl restart network
        sleep 1
    fi
done
export CREATED_NIC
echo "created NIC: '$CREATED_NIC'"
EOF
    script_output($conf_nic_script);

    my $created_nic = script_output('echo $CREATED_NIC');
    bmwqemu::fctwarn("pev: created_nic '$created_nic'"); # FIXME: debug
    if ($created_nic) {
        record_soft_failure("bsc#1157896, poo#60245: 'Missing configs for $created_nic! Please check!");
    }
}

1;
