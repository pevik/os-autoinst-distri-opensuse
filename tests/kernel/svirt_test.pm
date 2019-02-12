use 5.018;
use warnings;
use base 'opensusebasetest';
use testapi;

sub run {
    my $self = shift;

    bmwqemu::fctwarn("pev: before wait_boot\n"); # FIXME: debug
    $self->wait_boot;

    #select_console('root-console');
    #bmwqemu::fctwarn("pev: after root-console\n"); # FIXME: debug
    #type_string "export PS1='# '\n";
    bmwqemu::fctwarn("pev: before serial_term_prompt: '$testapi::distri->{serial_term_prompt}'\n"); # FIXME: debug
    $testapi::distri->{serial_term_prompt} = 'susetest:~ # ';
    bmwqemu::fctwarn("pev: after serial_term_prompt: '$testapi::distri->{serial_term_prompt}'\n"); # FIXME: debug

    #select_console('ssh-virtsh-serial');
    my $console = 'root-sut-serial';
    bmwqemu::fctwarn("pev: before selecting console $console\n"); # FIXME: debug
    select_console($console);
    bmwqemu::fctwarn("pev: after selecting console $console\n"); # FIXME: debug

    script_output('hostname');

    #bmwqemu::fctwarn("pev: SLEEPING :)\n"); # FIXME: debug
    #sleep; # FIXME: debug

    script_output('uname -a');
}
1;

=cut
SVIRT_TEST=1
=cut
