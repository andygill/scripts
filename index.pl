print "<div class=\"links\">\n";
print "  <table>\n";

while (<STDIN>) {
    if (/<h2/ && /<a name="(.*)">(.*)<\/a>/) {
	print "  <tr><td onclick=\"document.location='#$1'\"><a href=\"#$1\">$2</a></li></td></tr>\n";
    }
}

print "  </table>\n";
print "</div>\n";
