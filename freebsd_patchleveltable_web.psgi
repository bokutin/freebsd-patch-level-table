use lib do { __FILE__ =~ s{[^/]+$}{lib}r };
use File::Spec::Functions;
use FreeBSD_PatchLevelTable::Container;
use FreeBSD_PatchLevelTable::Web;
use Plack::Builder;

my $app = FreeBSD_PatchLevelTable::Web->to_app;
builder {
    # enable 'ReverseProxy';
    # enable 'ReverseProxyPath';
    # enable 'Chunked';
    # enable 'Deflater',
    #     content_type    => ['text/plain','text/css','text/html','text/javascript','application/javascript'],
    #     vary_user_agent => 1;
    enable 'Static', path => qr{^/static/}, root => catdir container('app_home'), 'pub';
    $app;
};
