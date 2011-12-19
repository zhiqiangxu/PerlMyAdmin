package Model::City;
use strict;
use warnings;
use base qw/Model::Base/;

sub of_province {
    my ($self, $province_id) = @_;
    my $sql = "SELECT * FROM city WHERE province_id=?";
    return $self->query($sql, [$province_id]);
}
1
