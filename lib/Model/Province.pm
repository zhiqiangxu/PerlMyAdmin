package Model::Province;
use strict;
use warnings;
use base qw/Model::Base/;

sub select_all {
    my ($self) = @_;
    my $sql = "SELECT * FROM province";
    return $self->query($sql);
}

1
