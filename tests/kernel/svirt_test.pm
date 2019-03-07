use 5.018;
use warnings;
use base 'opensusebasetest';
use testapi;

sub run {
    my $self = shift;
    my $out;

    $self->wait_boot;

    my $cmd = "hostname";
    $out = script_output($cmd);
    bmwqemu::diag("cmd: '$cmd', output: '$out'");
=cut
    bmwqemu::fctwarn("Using select_serial_terminal (backend: '" .
        get_var('BACKEND') . "')");
    $self->select_serial_terminal;

    assert_script_run('date');

    foreach my $cmd ("hostname", "uname -a") {
        $out = script_output($cmd);
        bmwqemu::diag("cmd: '$cmd', output: '$out'");
    }

    bmwqemu::fctwarn("ver_linux");
    script_run('wget -c https://github.com/linux-test-project/ltp/raw/master/ver_linux; chmod 755 ver_linux');
    my $ver_linux_log = '/tmp/ver_linux_before.txt';
    script_run("./ver_linux > $ver_linux_log 2>&1");
    upload_logs($ver_linux_log, failok => 1);
    my $ver_linux_out = script_output("cat $ver_linux_log");
    if ($ver_linux_out =~ qr'^Linux\s+(.*?)\s*$'m) {
        bmwqemu::fctwarn("kernel: '$1'");
    } else {
        bmwqemu::fctwarn("kernel: not found");
    }
=cut
}
1;

=head1 Configuration
Clone any s390-kvm-sle12 or any qemu job with:
SVIRT_TEST=1 NAME=SVIRT_TEST PUBLISH_HDD_1= PUBLISH_PFLASH_VARS=
=cut
