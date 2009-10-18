# Usage: perl togglecabal [True|False]
$buildable = $ARGV[0];
$count = 0;
foreach(<*.cabal>) {
    $cab = $_;
    print "fixing $cab\n";
    open (F,"<$cab");
    open (G,">$cab-TMP");
    $state = 0;
    while(<F>) {
	if (/^Executable\s+/)  {
	    $state = 1;
	} elsif (/^\S/) {
	    $state = 0;
	}
	if ($state && /(\s+buildable\s*:\s*)/) {
	    $_ = $1 . $buildable . "\n";
	    $count++;
        }
	print G $_;
    }
    system("mv $cab $cab-KEEP");
    system("mv $cab-TMP $cab");
}
print "changed $count instances of buildable to $buildable\n";

