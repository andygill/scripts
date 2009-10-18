#!/usr/bin/perl
# simple testing shell
#
# Version 0.1
# latest version from darcs repo
#   darcs http://darcs.unsafePerformIO.com/tesh
# 
# The idea is that this is what an observer of a test run would see.
#
# The commands are
#  % cat > Foo.hs
#    .. contents ...
#  % $COMMAND $ARGS other args ..
#
# Invoke:
#  tesh test1 test2 test3 ...
#
# Execution:
#   takes place in current directory.
#
# Result:
#   output placed into <test_name>.actual beside the test script.
# 
# Arguments:
#   --verbose	please be verbose
#   --silent    please be quiet (do not list diffs if test failed)
#   --env X=Y   add an environmental variable
#
# Extensions/commands:
#
#  cat > FILE     read a here style document from stdin, ends with a line starting with '% '
#  quit         explict end of test
#
# /^% /		a prompt, call a command
#
#  /^%% /       how to specify a single % at the line start.
# 

$mode = 'normal';
$DEBUG = 0;
$IGNORE_DATES = 0;
$VERBOSE = 0;
@IGNORE_PATHS = ();
@files = ();

while ($#ARGV > -1) {
    local $arg = shift @ARGV;
    if ($arg eq "--debug") {
	$DEBUG = 1;
    } elsif ($arg eq "-v" || $arg eq "--verbose") {
	$VERBOSE = 1;
	$SILENT  = 0;
    } elsif ($arg eq "-s" || $arg eq "--silent") {
	$VERBOSE = 0;
	$SILENT  = 1;
    } elsif ($arg eq "--env") {
	local $tmp_arg = shift @ARGV;
	if ($tmp_arg =~ /^([^=]*)=(.*)$/) {
	    $ENV{$1} = $2;
	} else {
	    die "bad argument to --env: $_";
	}
    } else {
	push(@files,$arg);
    }
}
if ($#files > 0) {
    die ("multiple test files specified\n\t" . join("\n\t",@files));
} elsif ($#files == -1) {
    die ("no test files specified\n");
} else {
  $test = $files[0];
}

select STDERR; $| = 1;	# make unbuffered
select STDOUT; $| = 1;	# make unbuffered

sub fix_output {
    $ln = shift;
    $ln =~ s/^% /%% /;
    $ln =~ s/(Sun|Mon|Tue|Wed|Thu|Fri|Sat)\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d+\s+\d\d:\d\d:\d\d\s+\d\d\d\d/[__SOME_DATE__]/g
	if ($IGNORE_DATES);
    $ln =~ s/^real\s+\d+m\d+\.\d\d\ds$/real [__REAL_TIME__]/
	if ($IGNORE_TIMES);
    $ln =~ s/^user\s+\d+m\d+\.\d\d\ds$/real [__USER_TIME__]/
	if ($IGNORE_TIMES);
    $ln =~ s/^sys\s+\d+m\d+\.\d\d\ds$/real [__SYS_TIME__]/
	if ($IGNORE_TIMES);

    foreach (@IGNORE_PATHS) {
	$re = $_;
	$ln =~ s/$re/[__SOME_PATH__]/g;
    }
    return $ln;
}

sub bad_exec {
    local $cmd = shift;
    print "failed (can not execute '$cmd')\n";    
    exit(1);
}
 
print "$test: " if (!$SILENT);
print "\n" if ($VERBOSE == 1);
local @cmds = ();

local $here = '';

open(FILE,"$test");
while(<FILE>) {
    if (/^%\s+(.*)$/) {
	push(@cmds,$here);
	$here = '';
	push(@cmds,$1);
    } else {
	s/^%% /% /;
	$here .= $_;
    }
}
close(FILE);

open(OUTFILE,">$test.actual") || die "failed (can not write $test.actual)";
local $header = shift(@cmds);
print OUTFILE $header;
while($#cmds > -1) {
	local $cmd = shift @cmds;
	local $here = shift @cmds;
	print OUTFILE "% $cmd\n";
	print STDOUT "% $cmd\n" if ($VERBOSE == 1);
	print "% $cmd\n" if ($DEBUG == 1);
	if ($cmd =~ /^\s*quit\s*$/) {
	    break;
	} elsif ($cmd =~ /^\s*ignore\s+dates\s*$/) {
	    $IGNORE_DATES = 1;
	} elsif ($cmd =~ /^\s*ignore\s+times\s*$/) {
	    $IGNORE_TIMES = 1;
	} elsif ($cmd =~ /^\s*ignore\s+path\s+(\S+)\s*$/) {
	    $dir = $1;
	    if ($dir =~ /^\//) {
		push(@IGNORE_PATHS,$1);
	    } else {
		$pwd = $ENV{'PWD'} . "/" . $dir;		
		while ($pwd =~ /[^\/]+\/(\.\.\/|\.\.$)/) {
		    $pwd = $` . $';
		}
		while ($pwd =~ /\/\./) {
		    $pwd = $` . $';
		}
		push(@IGNORE_PATHS,$pwd);
		print STDOUT "(ignoring path $pwd)\n" if ($VERBOSE == 1);
	    }
	} elsif ($cmd =~ /^cat\s+\>\s+(\S+)\s*$/) {
	    # here doc
	    open(TMPFILE,">$1") || bad_exec("cat > $1");
	    print TMPFILE ($here);
	    close(TMPFILE);
	    foreach (split(/\n/,$here)) {
		print OUTFILE (fix_output("$_\n"));
		print STDOUT "$_\n" if ($VERBOSE == 1);
            }
	} else {
	    local $pre_cmd = "";
	    local $extra_cmd = "";
	    local $time_cmd = "";
	    # need to check to see if stdout or stderr is redirected
	    if ($cmd =~ /^\[([^\]]+)\]\s*(.*)$/) {
		$pre_cmd = $1;
		$cmd = $2;
	    }
	    if ($pre_cmd =~ /fail/) {
		$extra_cmd = '; EXIT_CODE=$? ; if [ $EXIT_CODE == 0 ] ; then echo "? unexpected successful exit code : $EXIT_CODE" ; fi ';
	    } else {	# default is to check for exit code
		$extra_cmd = '; EXIT_CODE=$? ; if [ $EXIT_CODE != 0 ] ; then echo "? unexpected exit code : $EXIT_CODE" ; fi ';
	    }
	    if ($pre_cmd =~ /time/) {
		$time_cmd = "time";
	    }
	    if ($cmd =~ /^\s*tesh\s+(.*)$/) {
		$cmd = "perl $0 $1";	# tesh always is the same script again
	    }
	    if (open(CMD,"( $time_cmd $cmd $extra_cmd ) 2>&1 |") 
		|| bad_exec($cmd)) {
		while(<CMD>) {
		    s/^% /%% /;
		    print OUTFILE (fix_output($_));
		    print STDOUT $_ if ($VERBOSE == 1);
		}
		close(CMD);
	    } else {
		print OUTFILE "Command not found: $cmd\n";
		exit(1);
	    }
	}
}
close(OUTFILE);
if (!-e $test) {
    die "can not find $test for diff";
}
if (!-e "$test.actual") {
    die "can not find $test.actual for diff";
}

open(DIFF,"diff -wc $test $test.actual|") || die "can not find diff";
$good = 1;
while(<DIFF>) {
    if ($good == 1) {
        print "failed\n";
        $good = 0;
    }
    print "$_" if (!$SILENT);
}
close(DIFF);
if ($good) {
  print "passed\n" if (!$SILENT);
  exit(0);
} else {
  exit(1);
}
