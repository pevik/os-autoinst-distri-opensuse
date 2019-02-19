use 5.018;
use warnings;
use base 'opensusebasetest';
use testapi;

sub run {
    my $self = shift;
    my $out;

    $self->wait_boot;

    bmwqemu::fctwarn("Using select_serial_terminal (backend: '" .
        get_var('BACKEND') . "')");
    $self->select_serial_terminal;

    assert_script_run('date');

    foreach my $cmd ("hostname", "uname -a") {
        $out = script_output($cmd);
        bmwqemu::diag("cmd: '$cmd', output: '$out'");
    }
}
1;

=head1 Configuration
Clone any s390-kvm-sle12 or any qemu job with:
SVIRT_TEST=1 NAME=SVIRT_TEST PUBLISH_HDD_1= PUBLISH_PFLASH_VARS=
=cut
