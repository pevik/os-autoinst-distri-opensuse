use 5.018;
use warnings;
use base 'opensusebasetest';
use testapi;

sub run {
    my $self = shift;

    bmwqemu::fctwarn("pev: before wait_boot\n"); # FIXME: debug
    $self->wait_boot;
    bmwqemu::fctwarn("pev: after wait_boot\n"); # FIXME: debug

    #select_console('root-console');
    select_console('ssh-virtsh-serial');
    script_output('hostname');
    script_output('uname -a');
}
1;

=cut
SVIRT_TEST=1
=cut
