#!/usr/bin/perl
#
# Copyright (c) 2012 Dell Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Author: aabes
#


use v5.10;
use strict;

my $IPMITOOL = "/usr/bin/ipmitool";
my $cmd = "$IPMITOOL sensor";
my $warning_num = 0;
my $critical_num = 0;
my $fatal_error = 0;
my %state;
my @perfdata = ();
my %comp_state = { 'OK' =>[] , 'WARNING' =>[], 'CRITICAL' =>[] };

# make perl-setuid happy
$ENV{"PATH"} ="";

sub executeCommand {
	my $command = join ' ', @_;
	($_ = qx{$command 2>&1}, $? >> 8);
}

my ($output, $rc) = executeCommand($cmd);
printResultAndExit(2, "tool failedwith RC $rc.\n" . "OUTPUT: " . $output . "COMMAND: " . $cmd) unless ($rc == 0);

my @output = split(/\n/, $output);
foreach my $line (@output)
{
    my ($id_string, $state, $reading,$unit,$id_string_state, $output_str);

    ## format: (th = threshold)
    #   nam | reading | type | status | ? | th1 | th2 | th3 | th3 | ?
    
    if ($line =~ /\s*(.+?)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*(.+?)/) {
	($id_string,$reading,$unit,$state) = ($1,$2,$3,$4);
	next if $state =~ /na/;
	next if $unit =~ /discrete/;
    }  else  {
        print "Not parsable: $line";
        $fatal_error++;
        next;
    }

    given($state)  {
	when (/ok/)  {}
	when (/nc/) {
	    $warning_num++;
	    $output_str = 'WARNING';
	}
	when (/cr/) {
	    $critical_num++;
	    $output_str = 'CRITICAL';
	}
	default {
	    print "State not parsable  $state $line \n";
	    $fatal_error++;
	    next;
	}
    }
    push (@{$comp_state{$output_str}}, $id_string);
    push (@perfdata, "$id_string=${reading} ${unit}");
}

sub printResultAndExit {

    my $exitVal = shift;
    print "@_" if (defined @_);
    print "\n";
    exit($exitVal);
}


my $ret = 0;
my $failed = "";
RETURN: {
    if ($fatal_error)   { $ret = 3; last RETURN; }
    if ($critical_num)  { $ret = 2; last RETURN; }
    if ($warning_num)   { $ret = 1; last RETURN; }
}


if ($critical_num) {$failed = "CRIT:". join(",",@{$comp_state{'CRITICAL'}}); }
if ($warning_num) { $failed = $failed . " WARN:" .join(",",@{$comp_state{'WARNING'}}); }

printResultAndExit ($ret, $failed . " |" . join(',', @perfdata));
