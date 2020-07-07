#!/usr/local/bin/perl

use rlib;
use Modern::Perl;
use base qw(App::Cmd::Simple);

use File::Path qw(make_path);
use FindBin;
use FreeBSD_PatchLevelTable::Container;
use Process::Status;
use String::ShellQuote;

sub opt_spec {
    (
        # www.freebsd.org/security/advisories/FreeBSD-EN-19:10.scp.asc I experienced it updated.
        [ "check_remote", "Make sure the mtime and size also in the downloaded files" ],
    );
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $dir = container('config')->{project_dir} or die;
    -d or make_path($_) or die for $dir;

    my @cmd = (
        "wget",
        "-q",
        "-w", int(rand 5),
        #"-e", 'HTTP_PROXY=192.168.0.1:8080',
        #"-e", 'HTTPS_PROXY=192.168.0.1:8080',
        "-P", $dir,
        '--user-agent', 'Mozilla/5.0 (iPhone; CPU iPhone OS 7_0 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) Version/7.0 Mobile/11A465 Safari/9537.53',
    );

    #system(@cmd, qw(-np -nc -r -l inf --no-remove-listing https://www.freebsd.org/security/advisories/)) == 0 or die;
    #sleep int(rand 5);
    systemx(@cmd, qw(-x https://www.freebsd.org/security/advisories/));
    sleep int(rand 5);
    systemx(@cmd, qw(-x https://www.freebsd.org/security/security.html));
    sleep int(rand 5);
    systemx(@cmd, qw(-x https://www.freebsd.org/security/unsupported.html));
    systemx("script/fetch_advisories.pl", $opt->check_remote ? '-m' : ());
    systemx("script/asc_to_jsonl.pl                                                    > $dir/freebsd-patch-level-table.jsonl");
    systemx("script/table_to_jsonl.pl < $dir/www.freebsd.org/security/supported.html   > $dir/supported.jsonl");
    systemx("script/table_to_jsonl.pl < $dir/www.freebsd.org/security/unsupported.html > $dir/unsupported.jsonl");

    exit 0;
}

sub systemx {
    my $ret = system(@_);
    Process::Status->assert_ok( @_==1 ? $_[0] : shell_quote @_ );
    $ret;
}

__PACKAGE__->import->run;
