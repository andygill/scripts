# usage: GenerateBootPHP [bootfile|mysql] <user> <db>
$HOME = $ENV{'HOME'};

open(PASS,"$HOME/etc/db_pass");
while(<PASS>) {
    chop;
    my ($DB_USER,$DB_HOST,$DB_NAME,$DB_PASSWORD) = split(/:/,$_);
    if ($DB_USER eq $ARGV[1] && $DB_NAME eq $ARGV[2]) {
	if ("bootfile" eq $ARGV[0]) {
	    print "<?php\n";
	    print "\$DB_USER = '$DB_USER';\n";
	    print "\$DB_HOST = '$DB_HOST';\n";
	    print "\$DB_NAME = '$DB_NAME';\n";
	    print "\$DB_PASSWORD = '$DB_PASSWORD';\n";
	    print "?>\n";
	}
	if ("mysql" eq $ARGV[0]) {
	    if ($DB_PASSWORD ne "") {
		print "-p'$DB_PASSWORD' ";
	    }
	    print "-u'$DB_USER' -h'$DB_HOST' '$DB_NAME' ";
	}
    }
}
