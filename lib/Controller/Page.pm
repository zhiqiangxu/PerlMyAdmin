package Controller::Page;
use strict;
use warnings;

sub paginator{
    my ($self, $pager, $total_pages, $num) = @_;
    my ($start, $end, $i);
    $pager = ($pager < 1) ? 1 : ($pager > $total_pages ? $total_pages : $pager);
    $start = $pager - ($num - 1)/2;
    $start = $start < 1 ? 1 : $start;
    $end = $start + $num - 1;
    $end = $end > $total_pages ? $total_pages : $end;
    my %hash = ( LEFT => $start > 1 ? '...' : '', 'START'=> $start, 'END'  => $end, 'RIGHT'=> $end < $total_pages ? '...' : '' );
    return \%hash;
}

1
