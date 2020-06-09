# Copyright (C) 2019 SUSE LLC
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

package Utils::Systemd;

use base 'Exporter';
use Exporter;
use Carp 'croak';
use strict;
use warnings;
use testapi qw(script_run assert_script_run);

our @EXPORT = qw(
  enable_start_service
  disable_stop_service
  is_installed
  systemctl
);

=head2 disable_stop_service

    disable_stop_service($service_name[, mask_service => $mask_service]);

Disable and stop the service C<$service_name>.
Mask it if I<$mask_service> evaluates to true. Default: false

=cut
sub disable_stop_service {
    my ($service_name, %args) = @_;
    die "disable_stop_service(): no service name given" if ($service_name =~ /^ *$/);
    $args{mask_service}   //= 0;

    unless (is_installed($service_name)) {
        bmwqemu::fctwarn("service '$service_name' not installed");
        return 0;
    }

    if ($args{mask_service}) {
        systemctl("mask $service_name");
    } else {
        systemctl("disable $service_name");
    }

    systemctl("stop $service_name");

    return 1;
}

=head2 is_installed

    is_installed($service_name[, mask_service => $mask_service]);

Detect if service is installed.
Return 1 if service installed, otherwise 0.

=cut
sub is_installed {
    my $service_name = shift;
    die "disable_stop_service(): no service name given" if ($service_name =~ /^ *$/);

    return ! script_run("systemctl --all | grep -i $service_name");
}

=head2 systemctl

    systemctl($command[, fail_message => $fail_message][, ignore_failure => $ignore_failure][,timeout => $timeout]);

Wrapper around systemctl call to be able to add some useful options.

Please note that return code of this function is handled by 'script_run' or
'assert_script_run' function, and as such, can be different.
=cut
sub systemctl {
    my ($command, %args) = @_;
    croak "systemctl(): no command specified" if ($command =~ /^ *$/);
    my $expect_false  = $args{expect_false} ? '!' : '';
    my @script_params = ("$expect_false systemctl --no-pager $command", timeout => $args{timeout}, fail_message => $args{fail_message});

    if ($args{ignore_failure}) {
        return script_run($script_params[0], $args{timeout});
    } else {
        assert_script_run(@script_params);
    }
}

1;
