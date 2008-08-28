# build the call graph
$state = 0;
$node = 1;
%names  = ();
$depth = 0;
$prev_depth = 0;
%parents = ();

$cut_off = 2.0;

print "digraph states { size=\"4,2\"; node [shape=ellipse];\n";

%pairs = {};

foreach (@ARGV) {
    open(FILE,"$_");
    while(<FILE>) {
	if (/^module\s+(\S+)/) {
	    $module = $1;
	    push(@ismodule,$module);
	}
	
	if (/^import\s+qualified\s+([^\s\(]+)/ || /^import\s+([^\s\(]+)/) {
	    $pairs{$1} = join(',',($module,$pairs{$1}));
	}
    }
    close(FILE);
}

foreach (@ismodule) {
    $module = $_;
    foreach(split(',',$pairs{$module})) {
	print "\t\"$module\" -> \"$_\";\n";
    }
}
print "\n}\n";
