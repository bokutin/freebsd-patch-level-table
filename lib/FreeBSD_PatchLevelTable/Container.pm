package FreeBSD_PatchLevelTable::Container;

use Modern::Perl;
use Carp;
use Class::Load qw(load_optional_class);
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec::Functions qw(abs2rel catdir catfile splitdir);
use Module::Runtime qw(use_module);

sub new {
    my $class = ref $_[0] || $_[0]; shift;
    my $self = bless {}, $class;
    $self;
}

sub import {
    my $class = ref $_[0] || $_[0]; shift;
    my $name  = $_[0] || 'container';
    my $pkg   = caller;

    no strict 'refs';
    no warnings 'redefine';
    *{"${pkg}::${name}"} = sub {
        #             container('name') or
        #         $c->container('name') or
        # MyApp::Web->container('name') or
        # MyApp::Web::container('name')
        shift if @_ and ( ref $_[0] || $_[0] ) eq $pkg;

        if (@_) {
            my $method = shift;
            unless ($class->instance->can($method)) {
                confess "such a method not exists. ${class}::$method";
            }
            $class->instance->$method(@_);
        }
        else {
            $class->instance;
        }
    };
}

sub instance {
    my $class = shift;
    no strict 'refs';
    ${"${class}::INSTANCE"} ||= $class->new;
}

####################################################################################################

sub app_class {
    my $self = shift;
    $self->{app_class} //= ref($self) =~ s/::[^:]+$//r;
}

sub app_class_lc {
    my $self = shift;
    $self->{app_class_lc} //= lc $self->app_class;
}

sub app_home {
    my $self = shift;

    $self->{app_home} //= do {
        my $file = ref($self) =~ s/::/\//gr . '.pm';
        my $path = $INC{$file} or die;
        $path =~ s/$file$//;
        my @home = splitdir $path;
        pop @home while @home && ($home[-1] =~ /^b?lib$/ || $home[-1] eq '');
        abs_path(catdir(@home) || '.');
    };
}

sub config {
    my $self = shift;

    $self->{config} //= do {
        my $dir   = catdir($self->app_home, 'etc');
        my @files = (
            catfile($dir, "@{[$self->app_class_lc]}.pl"),
            catfile($dir, "@{[$self->app_class_lc]}_local.pl"),
        );
        use_module('Config::Merged')->load_files( { files => \@files, use_ext => 1 } );
    };
}

sub mason {
    my $self = shift;

    my $interp = $self->{mason} //= do {
        my %opt;
        my $in_package = "@{[ $self->app_class ]}::View";
        if ( load_optional_class($in_package) ) {
            $opt{in_package} = $in_package;
        }
        my $data_dir = catdir $self->config->{project_dir}||die, 'var/mason';
        -d or make_path($_) or die for $data_dir;
        use_module('HTML::MasonX::BOKUTIN::Factory')->new_web_interp(
            allow_globals => [qw($c $DISABLE_AUTO_ESCAPE)],
            comp_root     => [
                [ $self->app_class_lc => catdir( $self->app_home, "mason" ) ],
            ],
            data_dir      => $data_dir,
            plugins       => [ 'HTML::MasonX::BOKUTIN::Plugin::ProfileWithCatalystStats' ],
            %opt,
        );
    };
}

1;
