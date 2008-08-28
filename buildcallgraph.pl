# build the call graph
$state = 0;
$node = 1;
%names  = ();
$depth = 0;
$prev_depth = 0;
%parents = ();


$cut_off = 2.0;

sub addcommas {
    my ($txt,@rest) = @_;

    if ($txt =~ /(\d\d)(\d)\d\d\d\d\d$/) {
	if ($2 <= 5) {
	    $txt = $` . $1 . "m";
	} else {
	    $txt = $` . ($1 + 1) . "m";
	}
    } elsif ($txt =~ /(\d\d)(\d)\d\d$/) {
	if ($2 <= 5) {
	    $txt = $` . $1 . "k";
	} else {
	    $txt = $` . ($1 + 1) . "k";
	}
    }

    return "$txt";
}


print "digraph states { size=\"8,4\"; node [shape=ellipse];\n";

while(<STDIN>) {
    $state = 2 if (/^MAIN\s+MAIN\s+1/);
    if ($state == 2) {
	/^(\s*)(\S+)\s+(\S+)\s+\S+\s+(\S+)\s+\S+\s+\S+\s+(\S+)/;

#	print "($1) ($2 $3) ($4) ($5)\n";

	$names{$node} = $2;
	$mods{$node} = $3;
	$depth = length($1);

	while ($depth <= $#parents) {
	    pop(@parents);
	}

#	print ("parents : " . join(",",@parents) . "\n");

	if ($5 >= $cut_off)  {
	    $accounted{$node} = $5;
	    $parent_node = $parents[$#patents];
	    if (!defined ($parent_node)) {
		$parent_node = "MAIN";
	    }
	    $accounted{$parent_node} -= $5;
	    if ($2 ne "MAIN" && $2 ne "main") {
		my $short = addcommas($4);
		print "\t$parent_node -> $node [label=\"$short\\n$5%\"];\n" if ($parent_node != 1);
	    }
	}

	push(@parents,$node);
	$node++;
    }
}

foreach $key (keys %accounted) {
    next if ($key eq "MAIN" || $names{$key} eq "MAIN");
    $txt = "$names{$key}\\n$mods{$key}";
    if ($accounted{$key} > 0.1) {
	$time = $accounted{$key};
	if ($time < 2.0) {
	    $color = 'green';
	} elsif ($time < 4.0) {
	    $color = 'yellow';
	} elsif ($time < 8.0) {
	    $color = 'orange';
	} else {
	    $color = 'red';
	}
	printf ("$key [label=\"$txt\\n(%.2f)\",style=filled, fillcolor=$color];\n", $accounted{$key});
    } else {
	print "$key [label=\"$txt\", style=filled, fillcolor=white];\n";
    }
}

print "\n}\n";
