# SUSE's openQA tests
#
# Copyright © 2020 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

package klp;

use warnings;
use strict;

use Exporter 'import';

use testapi;
use utils;
use version_utils 'is_sle';

our @EXPORT = qw(
  install_klp_product is_klp_pkg find_installed_klp_pkg klp_pkg_eq
);

sub install_klp_product {
    my $arch    = get_required_var('ARCH');
    my $version = get_required_var('VERSION');
    my $release_override;
    my $lp_product;
    my $lp_module;
    if ($version eq '12') {
        $release_override = '-d';
    }
    if (!is_sle('>=12-SP3')) {
        $version = '12';
    }
    # SLE15 has different structure of modules and products than SLE12
    if (is_sle('15+')) {
        $lp_product = 'sle-module-live-patching';
        $lp_module  = 'SLE-Module-Live-Patching';
    }
    else {
        $lp_product = 'sle-live-patching';
        $lp_module  = 'SLE-Live-Patching';
    }

    #install kgraft product
    zypper_call("ar http://download.suse.de/ibs/SUSE/Products/$lp_module/$version/$arch/product/ kgraft-pool");
    zypper_call("ar $release_override http://download.suse.de/ibs/SUSE/Updates/$lp_module/$version/$arch/update/ kgraft-update");
    zypper_call("ref");
    zypper_call("in -l -t product $lp_product", exitcode => [0, 102, 103]);
    zypper_call("mr -e kgraft-update");
}

sub is_klp_pkg {
    my $pkg  = shift;
    my $base = qr/(?:kgraft-|kernel-live)patch/;

    if ($$pkg{name} =~ m/^${base}-\d+/) {
        if ($$pkg{name} =~ m/^${base}-(\d+_\d+_\d+-\d+_*\d*_*\d*)-([a-z][a-z0-9]*)$/) {
            my $kver    = $1;
            my $kflavor = $2;
            $kver =~ s/_/./g;
            return {
                name    => $$pkg{name},
                version => $$pkg{version},
                kver    => $kver,
                kflavor => $kflavor,
            };

        } else {
            die "Unexpected kernel livepatch package name format: \"$$pkg{name}\"";
        }
    }

    return undef;
}

sub klp_pkg_eq {
    my ($klp_pkg1, $klp_pkg2) = @_;

    return ($$klp_pkg1{name} eq $$klp_pkg2{name} &&
          $$klp_pkg1{version} eq $$klp_pkg2{version});
}

sub find_installed_klp_pkg {
    my ($kver, $kflavor) = @_;

    my $pkgs = zypper_search("-s -i -t package");
    my $klp_pkg;
    foreach my $pkg (@$pkgs) {
        my $cur_klp_pkg = is_klp_pkg($pkg);

        if ($cur_klp_pkg &&
            $$cur_klp_pkg{kver} eq $kver &&
            $$cur_klp_pkg{kflavor} eq $kflavor) {
            if ($klp_pkg && !klp_pkg_eq($klp_pkg, $cur_klp_pkg)) {
                die "Multiple live patch packages installed for kernel";
            }

            $klp_pkg = $cur_klp_pkg;
        }
    }

    return $klp_pkg;
}

1;
