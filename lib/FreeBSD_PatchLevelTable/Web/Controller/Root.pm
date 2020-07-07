package FreeBSD_PatchLevelTable::Web::Controller::Root;

use strict;
use base qw(Catalyst::Controller);

__PACKAGE__->config(namespace => '');

sub default :Private {
    my ($self, $c) = @_;

    $c->stash->{template} = '/main.mas';
    $c->forward( $c->view('Mason1') );
}

1;
