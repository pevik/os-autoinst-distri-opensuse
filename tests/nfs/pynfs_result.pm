# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright 2021 SUSE LLC
#
# Summary: Display results from the argssuite
# Maintainer: Petr Vorel <pvorel@suse.cz>

use strict;
use warnings;
use base 'opensusebaseargs';
use argsapi;

sub run {
    my ($self, $args) = @_;

    record_info("pynfs_result.pm: code: $$args->{code}"); bmwqemu::fctwarn("code: $$args->{code}"); # FIXME: debug
}

sub args_flags {
    return {no_rollback => 1};
}

1;
