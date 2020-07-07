#!/usr/local/bin/perl

use Modern::Perl;
use FreeBSD_PatchLevelTable::Container;
use IO::All;
use URI::Escape;
 
my $dir = container('config')->{project_dir} or die;

# https://www.freebsd.org/security/advisories/
my @href = io("$dir/www.freebsd.org/security/advisories/index.html")->all =~ m/href="(FreeBSD[^"]*?\.asc)"/g;

my @exists;
my @fetch;
for my $href (@href) {
    my $file = File::Spec->catfile("$dir/www.freebsd.org/security/advisories", uri_unescape($href));
    if (-f $file and !@ARGV) {
        push @exists, $href;
    }
    else {
        system("fetch", "-o", $file, @ARGV, "https://www.freebsd.org/security/advisories/$href");
        push @fetch, $href;
    }
}
#say 0+@exists;
#say 0+@fetch;
