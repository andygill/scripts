# Script to list other scripts

if ($0 =~ /(.*)\/\.pl/) {
    system "ls $1/*.pl $1/*.sh";
}

