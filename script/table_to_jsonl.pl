#!/usr/bin/env perl

use Modern::Perl;

use Date::Parse;
use FreeBSD_PatchLevelTable::Container;
use HTML::TableExtract;
use JSON::MaybeXS qw(:legacy);
use List::MoreUtils qw(mesh);
use POSIX qw(strftime);

sub str2time2ymd {
    my $str = shift;
    my $val = str2time($str) or return;
    strftime('%Y-%m-%d', gmtime($val));
}

my $in = do { local $/; <STDIN> };

my @headers = (qw(Branch Release Type Release Date EoL));
my $te = HTML::TableExtract->new( headers => \@headers );
$te->parse($in);

for my $ts ($te->tables) {
    for my $row ($ts->rows) {
        my %cols    = mesh @headers, @$row;
        $cols{Date} = str2time2ymd($cols{Date}) || $cols{Date};
        $cols{EoL}  = str2time2ymd($cols{EoL})  || $cols{EoL};
        say to_json \%cols;
    }
}
