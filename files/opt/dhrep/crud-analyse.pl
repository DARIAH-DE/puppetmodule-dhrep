#!/usr/bin/perl -w

# changelog fu 2013-01-29: added success parameter -s (see help)

use Getopt::Std;
getopts('l:c:hns');
use vars qw($opt_n $opt_l $opt_c $opt_h $opt_s);
use Time::Local;
#use Data::Dump qw(dump);

### constants
$default_logfile = "/var/log/textgrid/tgcrud/rollback.log";
$default_commentfile = "/var/log/textgrid/tgcrud/logcomments.log";
$default_crud_operation_duration_maximum_time_seconds = 60 * 5;

if (defined $opt_h) {
    print "$0\n";
    print "\tanalyses a batch of CRUD log files, trying hard to find irregularities, and then writes these into a log comment file.\n";
    print "\tthe script is meant for humans wanting to find CRUD bugs and to repair repository inconsistencies\n";
    print "\tOptions:\n";
    print "\t-h this help\n";
    print "\t-l the log file(s), separated by commas, e.g. 'log1.txt,log2.txt'. Default: $default_logfile\n";
    print "\t-c the output (log comments) file, default: $default_commentfile\n";
    print "\t-n Nagios mode: don't write a commentfile but return proper exit code and status text\n";
    print "\t-s Success mode: writes all completed operations to the log comment file\n";
    print "\t\n";
    exit 0;
}


$logfile = (defined $opt_l ) ? $opt_l : $default_logfile;
$commentfile = (defined $opt_c && (-w $opt_c || !-e $opt_c)) ? $opt_c : $default_commentfile ;
$nagiosmode = defined $opt_n ;
$successmode = defined $opt_s;

@logfiles = split ',', $logfile;
%h = ();
open COMMENT, ">$commentfile" unless $nagiosmode;

foreach $logfile (@logfiles) {
    if (!-e $logfile || !-r $logfile) {
	if ($nagiosmode) {
	    print "CRUD LOG FILE NOT FOUND - $logfile";
	    exit 2;
	} else {
	    print STDERR "$logfile does not exist or is not readable, skipping!\n";
	    next;
	}
    }
    open LOGFILE, $logfile;
    print STDERR "opening $logfile...\n" unless $nagiosmode;
    while (<LOGFILE>) {
    #    2011-05-09T01:04:44.531 INFO    TP-Processor16  531ddd49-4bbf-4d2e-9798-cf985036e9b9    UPDATEMETADATA  UNLOCKED        TG-URI  textgrid:37xt.0
	m/^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.+)$/;

	my ($time,$level,$thread,$uuid,$operation,$rest) = ($1,$2,$3,$4,$5,$6);
    
	if (! exists $h{$uuid}) {
	    $h{$uuid}= {};
	    $h{$uuid}{operation} = $operation;
	    $h{$uuid}{thread} = $thread;
	    $h{$uuid}{start} = $time;
	    $h{$uuid}{worked} = [];
	    
	    # just to make sure...
	    if (index ($rest, 'STARTED') != 0) {
#		print COMMENT "Ooops, this object $uuid did not have a regular start ($rest). Leftover at $time from a previous logfile?\n" unless $nagiosmode;
	    }
	} else {
	    if (index ($rest, 'STARTED') == 0) {
		push @{$h{$uuid}{worked}}, ($time, "XXXXX New operation before previous has been finished: ".$operation);
		$h{$uuid}{stackedop}++;
		next;
	    }
	    if ($level eq 'ERROR') {
		$h{$uuid}{error} = 1;
	    }
	    push @{$h{$uuid}{worked}}, ($time, $rest);
	}
	if (index ($rest, 'COMPLETE') == 0 && !exists $h{$uuid}{stackedop}) {
	    # Print out all completed events, if trigger "s" IS set.
	    if ($successmode) {
		print COMMENT $time . "\t" . $uuid . "\t" . $operation . "\t" . $rest . "\n";
	    }
	    delete $h{$uuid};
	    next;
	}
    }
    close LOGFILE;
} # next logfile

print STDERR "\n" unless $nagiosmode;

$evencounter = 0;
$nagioscounter = 0;

foreach $uuid (sort {$h{$a}{start} cmp $h{$b}{start}}  keys %h) {
    if (!$nagiosmode) {
	# Print out all NOT completed events, if triger "s" is NOT set.
	if (!$successmode) {
	    print COMMENT "Not complete: " . $h{$uuid}{operation} . " for $uuid started on ". $h{$uuid}{start} . '. What I did was: ' . join (' - ', grep {$evencounter++ % 2} @{$h{$uuid}{worked}}) . (exists $h{$uuid}{error} ? ' (ERROR)':'' ). (exists $h{$uuid}{stackedop} ? ' previous failed operations: '.$h{$uuid}{stackedop} :'' ). "\n";
	}
    } else {
	# figure out whether CRUD just recently started and might still be busy with this operation
	# 2012-01-17T13:12:18.543
	$h{$uuid}{start} =~ /(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)\.(\d+)/;
	my $now = time;
	my $thatstart = timelocal ($6,$5,$4,$3,$2-1,$1);
	my $difference = $now - $thatstart;
#	print $nagioscounter . ": the start ". $h{$uuid}{start} . " is " . $difference . " seconds from now.\n";
	if ($difference < $default_crud_operation_duration_maximum_time_seconds) {
	    next;
	}
	$nagioscounter++;
    }
}

if ($nagiosmode) {
    if ($nagioscounter > 1) {
	print "CRUD LOG FILE INCOMPLETE - $nagioscounter open transactions|'Open Transactions'=$nagioscounter;1;;0;";
	exit 1;
    } elsif ($nagioscounter == 1) {
	print "CRUD LOG FILE INCOMPLETE - one open transaction|'Open Transactions'=$nagioscounter;1;;0;";
	exit 1;
    } else {
	print "CRUD LOG FILE OK - no open transactions|'Open Transactions'=$nagioscounter;1;;0;";
	exit 0;
    }
} else {
    close COMMENT;
}
