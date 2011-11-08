# script to test the sdist version

do 'sdist.conf' || die "no sdist.conf file";
#Example of sdist.conf
#@GHCVER=("/usr/bin/ghc-7.0.3");
#@OPTS=("","-fall");

sub run {
    my $cmd = $_[0];
    print "$cmd\n";
    system($cmd);
    # from http://perldoc.perl.org/functions/system.html
    if ($? == -1) {
	print "failed to execute: $!\n";
	die;
    }
    elsif ($? & 127) {
	printf "child died with signal %d, %s coredump\n",
	($? & 127), ($? & 128) ? 'with' : 'without';
	die;
    }
    elsif (($? >> 8) != 0) {
	printf "child exited with value %d\n", $? >> 8;
	die;
    }
}

$TESTDIR = "testdist";

$cabal_file = <*.cabal>;
open(F,$cabal_file) || die "can not open $cabal_file";
while(<F>) {
  if (/^[Nn]ame:\s+(\S+)/) {
      $name = $1;
  }
  if (/^[Vv]ersion:\s+(\S+)/) {
      $version = $1;
  }
}
close(F);
print "($name $version)\n";

foreach my $GHCVER (@GHCVER) {
    foreach my $OPTS (@OPTS) {
	foreach my $STYLE ("configure","install") {
	    print "##########################################\n";
	    print "GHC=$GHCVER, OPTS=$OPTS, STYLE=$STYLE\n";

	    run("cabal sdist");
	    run("rm -Rf $TESTDIR");
	    run("mkdir $TESTDIR");
	    chdir($TESTDIR);
	    run("tar xvzf ../dist/$name-$version.tar.gz");
	    chdir("$name-$version");
	    if ($STYLE eq "configure") {
		run("cabal configure --with-compiler=$GHCVER $OPTS");
		run("cabal build");
	    } else {
		run("cabal install --with-compiler=$GHCVER $OPTS");
	    }
	}
    }
}
