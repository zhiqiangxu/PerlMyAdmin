package Controller::City::Get;

use strict;
use warnings;
use base qw/Controller::Base/;
use Model::City;

sub display {
    my ($self) = @_;
    my $city = Model::City->new;
    my $data = $city->of_province($self->param('province'));
    $self->output_json($data);
}

1
