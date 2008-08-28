# turn some text into a blog posting.
# <code>..</code>
#
# \n\n ==> 
$arg = shift;
$html = 0;

if ($arg eq "--html") {
    $html = 1;
}

sub codefrag {
    my ($ln,@other) = @_;
    $ln =~ s/\&/&amp;/g;
    $ln =~ s/\</&lt;/g;
    $ln =~ s/\>/&gt;/g;
    $ln =~ s/\"/&quot;/g;
#    $ln =~ s/\\/&#92;/g;
#    while ($ln =~ /^(\s*)\s/) {
#	$ln = $1 . "&nbsp;" . $';
#    }
    return "$ln";
}

$mode = 'txt';
$codelines = 0;

foreach(<STDIN>) {
    if ($mode eq 'txt' && /^<code>$/) {
	$mode = 'code';
	print "\n\n<pre lang=\"haskell\">";
	$codelines = 0;
    } elsif ($mode eq 'txt' && /^<command>$/) {
	$mode = 'code';
	print "\n\n<pre lang=\"none\">";
	$codelines = 0;
    } elsif ($mode eq 'code' && /^<\/(code|command)>$/) {
	$mode = 'txt';
	print "</pre>\n\n";
    } elsif ($mode eq 'code') {
#	if (++$codelines > 1) {
#	    print "\n";
#	}
	print($_);
#	chop($_);
#	print "<br/>" if ($html == 1);
    } elsif(/^\s+$/) {
	print "\n\n";
#	print "<br/>" if ($html == 1);
    } else {
	$xs = $_;
	$ys = "";
	while ($xs =~ /(\<code\>)([^\/]*)(\<\/code\>)/) {
	    $ys .= $` . $1 . codefrag($2) . $3;
	    $xs = $';
	}
	$ys .= $xs;
	chop($ys);
	print "$ys ";
    }
}

