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
use testapi;
use upload_system_log;

use Data::Dumper; # FIXME: debug

sub display_results {
    my $self = shift;
    my $dir ='~/pynfs/$folder';

    my $folder = get_required_var('PYNFS');

    assert_script_run("cd ~/pynfs/$folder");
    upload_logs('results.json', failok => 1);

    my $content = script_output('cat results.json');
    bmwqemu::fctwarn("content: '$content'"); # FIXME: debug
    my $results = Mojo::JSON::decode_json($content);

    bmwqemu::fctwarn("ref \$results->{testcase}: " . ref($results->{testcase})); # FIXME: debug
    die 'failed to parse results.json' unless $results;
    die 'results.json is not array' unless (ref($results->{testcase}) eq 'ARRAY');

    record_info('Results', "failures: $results->{failures}\nskipped: $results->{skipped}\ntime: $results->{time}");

    for my $test ($results->{testcase}) {
        bmwqemu::fctwarn("ref \$test: " . ref($test)); # FIXME: debug

        record_info("classname: $test->{classname}"); bmwqemu::fctwarn("classname: $test->{classname}"); # FIXME: debug
        record_info("code: $test->{code}"); bmwqemu::fctwarn("code: $test->{code}"); # FIXME: debug
        record_info("name: $test->{name}"); bmwqemu::fctwarn("name: $test->{name}"); # FIXME: debug
        record_info("time: $test->{time}"); bmwqemu::fctwarn("time: $test->{time}"); # FIXME: debug

        if (exists($test->{skipped})) {
            record_info("skipped: $test->{skipped}"); bmwqemu::fctwarn("skipped: $test->{skipped}"); # FIXME: debug
        }

        if (exists($test->{failure})) {
            record_info("failure: $test->{failure}"); bmwqemu::fctwarn("failure: $test->{failure}"); # FIXME: debug
        }

        my $targs = OpenQA::Test::RunArgs->new();
        $targs->{data} = $test;
        autotest::loadtest("tests/nfs/pynfs_result.pm", name => $test->{code}, run_args => $targs);
    }
}

# FIXME: debug
sub upload_pynfs_log {
    my $self = shift;
    my $folder = get_required_var('PYNFS');

    assert_script_run("cd ~/pynfs/$folder");

    upload_logs('results.json', failok => 1);

=cut
    script_run('../showresults.py result-raw.txt > result-analysis.txt');
    upload_logs('result-analysis.txt', failok => 1);

    script_run('../showresults.py --hidepass result-raw.txt > result-fail.txt');
    upload_logs('result-fail.txt', failok => 1);

    if (script_output("cat result-fail.txt | grep 'Of those:.*Failed' | sed 's/.*, \\([0-9]\\+\\) Failed,.*/\\1/'") gt 0) {
        $self->result("fail");
        record_info("failed tests", script_output('cat result-fail.txt'), result => 'fail');
    }
=cut
}

sub upload_cthon04_log {
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

    if (get_var("PYNFS")) {
        $self->display_results();
    }
    elsif (get_var("CTHON04")) {
        $self->upload_cthon04_log();
    }
    upload_system_logs();
}

1;
