# run cabal test 
use Cwd;
my $dir = getcwd();
my @back = (reverse(split(/\//,$dir)));

$cabal = '';
$up = 0;
while (true) {
    $cabal = '';
    $uptxt = "../" x $up;
    foreach(<$uptxt*.cabal>) {
	$cabal = $_;
    }
    last if ($cabal ne '');
    die "Could not find *.cabal (sorry)\n" if ($dir eq "/");
    $up++;
}

$lookupfor = join("/",reverse(splice(@back,0,$up)));
open(CABAL,"$dir/$cabal");

my $exec = '';
while(<CABAL>) {
    if (/^executable\s+(\S+)/i) {
	$exec = $1;
    }
    if (/\s+Hs-Source-Dirs/i && /$lookupfor/) {
	last;
    }
}

die "could not find any exec in this directory" if ($exec eq '');

$exec_file = ("./" . "../" x $up . "dist/build/" . $exec . "/" . $exec);

exec ("$exec_file",@ARGV);

