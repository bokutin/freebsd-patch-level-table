package FreeBSD_PatchLevelTable::Web::View::Mason1;
# ABSTRUCT: streaming response with $m->flush_buffer and non-blocking response with $c->res->write

use Moose;
extends 'Catalyst::View';
with 'Catalyst::Component::ApplicationAttribute';

use File::Spec::Functions;
use List::Flatten;
use List::MoreUtils qw(uniq);
use Module::Runtime qw(use_module);
use Scalar::Util qw(weaken);

use FreeBSD_PatchLevelTable::Container;

sub interp { container('mason') }

sub ACCEPT_CONTEXT {
    my ($self, $c, @args) = @_;
    unless ($c->stash->{"__@{[ref($self)]}_ACCEPT_CONTEXT_DONE"}++) {
        my $interp = $self->interp;
        if ( grep $_ eq '$c', $self->interp->compiler->allow_globals ) {
            no strict 'refs';
            weaken( ${$self->interp->compiler->in_package."::c"} = $c );
        }
    }
    $self;
}

sub filter {
    # my ($self, $ref, $c) = @_;
    # $$ref =~ s{foo}{bar};
}

sub process {
    my ($self, $c) = @_;

    #my $output;
    my $out_method = sub {
        $self->filter(\$_[0], $c);
        $c->res->content_type('text/html; charset=utf-8') unless $c->res->content_type;
        # $m->flush_buffer がリクエスト中(1)に呼ばれるか、リクエスト後(0)に呼ばれるか
        if ($c->res->finalized_headers or HTML::Mason::Request->instance->{top_stack}) {
            $c->res->write($_[0]);
        }
        else {
            $c->res->body($_[0]) if $_[0] =~ /\S/;
        }
    };
    my $comp = $self->_get_component($c);

    $self->interp->make_request(
        comp       => $comp,
        out_method => $out_method,
        args       => [%{$c->stash}],
    )->exec;

    #$c->res->body($output) if defined $output;
}

sub render {
    my ($self, $c, $comp, $args) = @_;

    my $output;
    my $out_method = sub {
        $self->filter(\$_[0], $c);
        $output //= '';
        $output .= $_[0];
    };

    $self->interp->make_request(
        comp       => $comp,
        out_method => $out_method,
        args       => [$args ? %$args : %{$c->stash}],
    )->exec;

    $output;
}

# このメソッド名は Catalyst::View::Mason, Catalyst::View::HTML::Mason 由来
sub _get_component {
    my ($self, $c) = @_;

    my @candidates = uniq grep $_, flat $c->stash->{template};
    unless (@candidates) {
        push @candidates, $c->action->name;
    }

    for my $candidate (@candidates) {
        my $comp_path = $candidate;
        unless ($comp_path =~ m{^/}) {
            $comp_path = catfile('/template', $c->action->namespace, $comp_path);
        }
        unless ($comp_path =~ m{\.mas$}) {
            $comp_path .= '.mas';
        }
        if ($self->interp->comp_exists($comp_path)) {
            $c->log->debug("Mason1: $comp_path found.");
            return $comp_path;
        }
        else {
            $c->log->debug("Mason1: $comp_path not found.");
        }
    }

    die "Mason components [@{[ join(', ', @candidates) ]}] not found.";
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
