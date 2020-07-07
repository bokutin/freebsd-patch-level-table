#!/usr/bin/env perl

use Modern::Perl;

use FreeBSD_PatchLevelTable::Container;
use IO::All;
use JSON::MaybeXS qw(:legacy);

my $dir = container('config')->{project_dir} or die;
my @asc = grep /\.asc$/, io("$dir/www.freebsd.org")->All_Files;

for my $asc (@asc) {
    my $corrected = $asc->all =~ /Corrected:(.*?)^[A-Z]/ms ? $1 : next;
    # 2015-07-28 19:58:54 UTC (stable/9, 9.3-STABLE)
    while ($corrected =~ /(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2}) (\S+) \((.*?)\)/g) {
        my ($ymd, $hms, $zone, $where) = ($1, $2, $3, $4);
        #my ($branch, $version) = split /\s*,\s*/, $where;
        #die unless $zone eq 'UTC';
        #say "@{[ $asc->pathname ]} $where";
        if ($where =~ m{^((?:releng|stable)\S+), (.*)}) {
            say to_json {
                branch   => $1,
                tag      => $2,
                asc      => $asc->filename,
                datetime => "$ymd $hms UTC",
            };
        }
    }
}
