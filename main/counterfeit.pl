#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Storable qw(dclone);
use POSIX qw(floor);
use Getopt::Long;
use Getopt::Std;
use CGI qw/header/;

sub counterfeit_coin_max {
    my ($x) = @_;
    return $x > 0 ? (3**$x-1)/2 : 1;            #(2)
}

sub counterfeit_coin_weight_xyz {
    my ($xy, $z, $G, $parent) = @_;
    my @nodes;
    if(not $parent->[4]){
        $parent->[4] = [];
    }
    if(in_array($xy->[@$xy - 1], $G)){
        pop @$xy;
    }
    #case 1: $xy balances
    push @nodes, [[@$z], [@$xy, @$G], [], []];
    push @{$parent->[4]}, {weight => $xy, node => $nodes[$#nodes]};
    my @part1 = @$xy[0..floor((@$xy - 1)/2)];
    my @part2 = @$xy[floor((@$xy + 1)/2)..@$xy - 1];

    #case 2: lt
    push @nodes, [[], [@$G, @$z], [@part2], [@part1]];
    push @{$parent->[4]}, {weight => $xy, node => $nodes[$#nodes]};
    #case 3: gt
    push @nodes, [[], [@$G, @$z], [@part1], [@part2]];
    push @{$parent->[4]}, {weight => $xy, node => $nodes[$#nodes]};
    return @nodes;
}

sub in_array {
    my ($x, $array) = @_;
    for my $e (@$array){
        return 1 if $e == $x;
    }
    return;
}

sub array_exclude {
    my ($a, $exc) = @_;
    my @result;
    map {push @result, $_ if not in_array($_, $exc)} @$a;
    return @result;
}

sub array_common {
    my ($a, $b) = @_;
    my @result;
    map {push @result, $_ if in_array($_, $b)} @$a;
    return @result;
}

sub counterfeit_coin_update {
    my ($OH, $OL, $NH, $NL) = @_;
    my (@g, @h, @l);
    for my $e (@$OH, @$OL){
        if(in_array($e, $NH) and (not in_array($e, $OL))){
            push @h, $e;
        }
        elsif(in_array($e, $NL) and (not in_array($e, $OH))){
            push @l, $e;
        }
        else{
            push @g, $e;
        }
    }

    return (\@g, \@h, \@l);
}

sub counterfeit_coin_weight_hlg {
    my ($hlg, $H, $L, $G, $parent) = @_;
    my @nodes;
    if(not $parent->[4]){
        $parent->[4] = [];
    }
    if(in_array($hlg->[@$hlg - 1], $G)){
        pop @$hlg;
    }
    #case 1: balances
    push @nodes, [[], [@$G, @$hlg], [array_exclude($H, $hlg)], [array_exclude($L, $hlg)]];
    push @{$parent->[4]}, {weight => $hlg, node => $nodes[$#nodes]};
    my @part1 = @$hlg[0..floor((@$hlg -1)/2)];
    my @part2 = @$hlg[floor((@$hlg + 1)/2)..@$hlg - 1];

    my ($g, $h, $l);
    #case 2: lt
    ($g, $h, $l) = counterfeit_coin_update($H, $L, \@part2, \@part1);
    push @nodes, [
        [], 
        [@$G, @$g], 
        [@$h],
        [@$l]
    ];
    push @{$parent->[4]}, {weight => $hlg, node => $nodes[$#nodes]};
    #case 3: gt
    ($g, $h, $l) = counterfeit_coin_update($H, $L, \@part1, \@part2);
    push @nodes, [
        [], 
        [@$G, @$g], 
        [@$h],
        [@$l]
    ];
    push @{$parent->[4]}, {weight => $hlg, node => $nodes[$#nodes]};
    return @nodes;
}

=select $x from $H and $L bins 
=cut
sub counterfeit_coin_selecthl {
    my ($x, $H, $L, $G) = @_;
    if(not $x > 0){
        $x = 1;
    }
    my @hl;
    my ($more, $few);
    if(@$H >= @$L){
        $more = $H;
        $few = $L;
    }
    else{
        $more = $L;
        $few = $H;
    }
    if(exists $more->[$x - 1]){
        for my $i (0..$x - 1){
            push @hl, $more->[$i];
        }
    }
    else{
        # take all $more plus $nfew $few
        my $nfew = $x - @$more;
        my $half = floor(($x - 1)/2);
        # grab half $more and half $few, then the other half of both
        # so that left h + right l is close to left l + right h
        for my $i (0..floor((@$more - 1)/2)){
            push @hl, $more->[$i];
        }
        for my $i (0..$half - (floor(@$more + 1)/2)){
            push @hl, $few->[$i];
        }
        for my $i (floor((@$more - 1)/2) + 1..@$more - 1){
            push @hl, $more->[$i];
        }
        for my $i ($half - floor((@$more + 1)/2) + 1..$nfew - 1){
            push @hl, $few->[$i];
        }
    }
    if(1 == @hl%2){
        push @hl, $G->[0];
    }
    return @hl;
}

sub counterfeit_coin_branch {
    my ($k, @nodes) = @_;
    my @next;
    for my $node (@nodes){
        my ($E, $G, $H, $L) = @$node;
        if(@$E){
            if(1 == @$E){
                next;
            }
            #@z should contain no more than (3**(k-1)+1)/2            (1)
            #@xy should contain no more than 3**(k-1), plus it MUST be even
            my (@xy, @z);
            my $count = 0;
            my $xy = @$G ? 3**($k-1) : 3**($k-1) - 1;#(1) will hold according to (2)
            for my $i (@$E){
                if($count < $xy){
                    push @xy, $i;
                    $count++;
                }
                else{
                    push @z, $i;
                }
            }
            if(1 == @xy%2){
                push @xy, $G->[0];
            }
            #now that we've chosen the coins, let's do weighting
            push @next, counterfeit_coin_weight_xyz(\@xy, \@z, $G, $node);
        }
        elsif(@$H or @$L){
            if(1 == (@$H + @$L)){
                next;
            }
            #just ensure to leave a combined total of 3**(k-1) or less in the H and L bins
            my $hl = 3**($k-1);
            my @hl = counterfeit_coin_selecthl(@$H + @$L - $hl, $H, $L, $G);
            push @next, counterfeit_coin_weight_hlg(\@hl, $H, $L, $G, $node);
        }
    }
    return @next;
}

sub counterfeit_coin_print {
    my ($node, $indent) = @_;
    $indent ||= 0;
    my ($NE, $NG, $NH, $NL, $NC) = @$node;
    print ('|' . (' ' x $indent) . (join ',', @$NE) . '; ' . (join ',', @$NG) . '; ' . (join ',', @$NH) . '; ' . (join ',', @$NL) . '; ' . $/);
    if($NC and @$NC){
        print '|' . (' ' x ($indent + 2)) . '(weight ' . (join ',', @{$NC->[0]{weight}}) . ')' . $/;
        for my $child (@$NC){
            counterfeit_coin_print($child->{node}, $indent + 2);
        }
    }
}

sub counterfeit_coin_check {
    my ($x, $n, $root) = @_;
    my ($E, $G, $H, $L, $children) = @{$root};
    if(@$E + @$G + @$H + @$L != $n){
        print 'something wrong3 at ' . $x . $/;
        print Dumper($E);
        print Dumper($G);
        print Dumper($H);
        print Dumper($L);
        exit;
    }
    if($children){
        map {counterfeit_coin_check($x, $n, $_->{node});} @$children;
    }
}

sub counterfeit_coin {
    my ($n, $x) = @_;
    if($n > counterfeit_coin_max($x)){
        print "This is just impossible." . $/;
        return;
    }
    #initialize
    my (@E, @G, @H, @L, @next);
    @E = 1 .. $n;
    my $root = [\@E, \@G, \@H, \@L];
    push @next, $root;
    while($x > 0){
        @next = counterfeit_coin_branch($x, @next);
        counterfeit_coin_check($x, $n, $root);
        $x--;
    }
    counterfeit_coin_print($root);
}

print header(-type=>'text/html',-charset=>'utf8');

my $cgi = CGI->new;
if($cgi->param('n') and $cgi->param('x')){
    counterfeit_coin($cgi->param('n'), $cgi->param('x'));
}
else{
    print "invalid parameter";
}
