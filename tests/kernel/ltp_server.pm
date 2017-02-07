# SUSE's openQA tests
#
# Copyright © 2017 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
#
# Summary: This module starts services and other things needed for
# parallelized test of networking part of the LTP (Linux Test Project).
# Maintainer: Petr Vorel <pvorel@suse.cz>

use strict;
use warnings;
use base 'opensusebasetest';

use testapi;
use lockapi;
use mmapi;

sub run {
    my $liface = get_var('LTP_LHOST_IFACES') || 'ens4';
    my $config = "/etc/sysconfig/network/ifcfg-$liface";


=cut
IPV4_NETWORK=192.168.122 \
IPV4_NET_REV=122.168.192 \
LHOST_IPV4_HOST=237 \
RHOST_IPV4_HOST=176 \
RHOST=$IPV4_NETWORK.$RHOST_IPV4_HOST \
IPV6_NETWORK=fe80::5054:ff \
IPV6_NET_REV=f.f.0.0.4.5.0.5.0.0.0.0.0.0.0.0.0.0.0.0.0.8.e.f \
LHOST_IPV6_HOST=fe2d:cc21 \
LHOST_IPV6_REV=1.2.c.c.d.2.e.f  \
RHOST_IPV6_HOST=fe96:7a60 \
RHOST_IPV6_REV=0.6.a.7.6.9.e.f \
LHOST_IFACES=ens4 \
RHOST_IFACES=ens4 \
PASSWD=test TST_USE_SSH=1 /opt/ltp/testscripts/network.sh -c
=cut

    # FIXME: fix address
    assert_script_run(qq(cp -v $config $config.backup && printf 'LLADDR=11:22:33:44:55:66\nIPADDR=192.168.122.2/24\n' >> $config && systemctl restart network));

    mutex_create('ltp_server_ready');

    script_run('ps axf');
    script_run('netstat -ap');

    script_run('cat /etc/resolv.conf');
    script_run('cat /etc/nsswitch.conf');
    script_run('cat /etc/hosts');

    script_run('env');

    script_run('ip addr');
    script_run('ip route');

    wait_for_children;
    assert_script_run("mv -v $config.backup $config");
}

1;

=head1 Configuration

Test to be run requires LTP_SERVER=1 to be set.
Tests which use this test require PARALLEL_WITH to be set with name of this test suite.

See also run_ltp.pm.

=cut

# vim: set sw=4 et:
