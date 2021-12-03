# SUSE's openQA tests
#
# Copyright 2021 SUSE LLC
# SPDX-License-Identifier: FSFAP
#
# Summary: Upload logs and generate report
# Maintainer: Yong Sun <yosun@suse.com>
package generate_report;

use strict;
use warnings;
use base 'opensusebasetest';
use Mojo::JSON;
use File::Basename 'basename';
use testapi;
use upload_system_log;

sub pynfs_display_results {
    my ($self, $log) = @_;
    my $content = script_output("cat $log");
    my $results = Mojo::JSON::decode_json($content);
    my $skip = "";
    my $pass = "";

    die "failed to parse '$log'" unless $results;
    die "'$log' is not array" unless (ref($results->{testcase}) eq 'ARRAY');

    record_info('Results', "failures: $results->{failures}\nskipped: $results->{skipped}\ntime: $results->{time}");

    for my $test (@{$results->{testcase}}) {
        if (exists($test->{skipped})) {
            $skip .= "$test->{code}\n";
        } elsif (!exists($test->{failure})) {
            $pass .= "$test->{code}\n";
        }
    }

    record_info('Passed', $pass);
    record_info('Skipped', $skip);

    for my $test (@{$results->{testcase}}) {
        bmwqemu::fctinfo("code: $test->{code}");
        next unless (exists($test->{failure}));

        my $targs = OpenQA::Test::RunArgs->new();
        $targs->{data} = $test;
        autotest::loadtest("tests/nfs/pynfs_failed.pm", name => $test->{code}, run_args => $targs);
    }
}

sub pynfs_upload_logs {
    my ($self, $log) = @_;

    my $log_worker = Mojo::File::path("ulogs/" . basename($log));

    mkdir($log_worker->dirname) if (!-d $log_worker->dirname);
    upload_logs($log, log_name => $log_worker->basename, failok => 1);
    bmwqemu::fctwarn("\$log_worker->to_string: '$log_worker->to_string', exists: " . (-e $log_worker->to_string ? "yes": "no")); # FIXME: debug

    return unless -e $log_worker->to_string;

    local @INC = ($ENV{OPENQA_LIBPATH} // testapi::OPENQA_LIBPATH, @INC);
    eval {
        require OpenQA::Parser::Format::XUnit;

        my $parser = OpenQA::Parser::Format::XUnit->new()->load($log_worker->to_string);

        $parser->write_output(bmwqemu::result_dir());
        $parser->write_test_result(bmwqemu::result_dir());

        $parser->tests->each(sub {
                $autotest::current_test->register_extra_test_results([$_->to_openqa]);
        });
    };
    die $@ if $@;
}

sub cthon04_upload_logs {
    my $self = shift;
    assert_script_run('cd ~/cthon04');
    if (script_output("grep 'All tests completed' ./result* | wc -l") =~ '4') {
        record_info('Complete', "All tests completed");
    }
    else {
        $self->result("fail");
        record_info("Test fail: Not all test completed");
    }
    if (script_output("grep ' ok.' ./result_basic_test.txt | wc -l") =~ '9') {
        record_info('Pass', "Basic test pass");
    }
    else {
        $self->result("fail");
        record_info('Fail', "Basic test failed");
    }
    if (script_output("egrep ' ok|success' ./result_special_test.txt | wc -l") =~ '7') {
        record_info('Pass', "Special test pass");
    }
    else {
        $self->result("fail");
        record_info('Fail', "Special test failed");
    }
    if (script_run("grep 'Congratulations' ./result_lock_test.txt")) {
        $self->result("fail");
        record_info('Fail', "Lock test failed");
    }
    else {
        record_info('Pass', "Lock test pass");
    }
    upload_logs('result_basic_test.txt', failok => 1);
    upload_logs('result_general_test.txt', failok => 1);
    upload_logs('result_special_test.txt', failok => 1);
    upload_logs('result_lock_test.txt', failok => 1);
}

sub run {
    my $self = shift;
    $self->select_serial_terminal;

    my $pynfs = get_var('PYNFS');

    if ($pynfs) {
        my $dir = "~/pynfs/$pynfs";
        my $log = "$dir/results.json";
        assert_script_run("cd $dir");
        $self->pynfs_display_results($log);
        $self->pynfs_upload_logs($log);
    }
    elsif (get_var("CTHON04")) {
        $self->cthon04_upload_logs();
    }

    upload_system_logs();

    autotest::loadtest("tests/shutdown/shutdown.pm");
}

sub test_flags {
    return {no_rollback => 1};
}

1;
