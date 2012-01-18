package Controller::Project::List;
use strict;
use warnings;
use base qw/Controller::Project/;
use Constants qw/TRUE/;
use Date::Calc qw/Today Delta_Days/;

sub generate_filter {
    my ($self, $name, $closed) = @_;
    my $where = '';
    my @bindings;
    if($name){
        $where .= 'AND name LIKE ?';
        push @bindings, '%' . $name . '%';
    }
    if($closed eq '0' || $closed eq '1'){
        $where .= 'AND closed = ?';
        push @bindings, $closed;
    }
    if($where){
        $where = 'WHERE ' . substr($where, 4); 
    }
    return {where => $where, bindings => \@bindings};
}


sub display {
    my ($self) = @_;
    $self->authenticate;
    my ($page, $name) = ($self->param('page') ? $self->param('page') : 1, $self->param('name'));
    my @closedloop = ({value => 1, name => '是'}, {value => 0, name => '否'});
    if($self->param('closed') eq '1' || $self->param('closed') eq '0'){
        for my $closed (@closedloop){
            if($closed->{value} == $self->param('closed')){
                $closed->{selected} = 1;
            }
        }
    }
    my $result = $self->do_table_select('project', TRUE, $self->generate_filter($self->param('name'), $self->param('closed')));
    my ($page_ref, $records_ref) = ($result->{page_ref}, $result->{records_ref}); 
    $self->blend_records($records_ref);
    $self->modify_days_outlook($records_ref);

    my $paginator = [];
    do {
        foreach my $i ($page_ref->{START} .. $page_ref->{END}){
            if($page == $i){
                push @$paginator,{lone => $i};
            }
            else {
               push @$paginator,{link => $i, href => $self->generate_uri({page => $i})};
            }
        }
    } unless $page_ref->{START} eq $page_ref->{END};
    my $page;
    if(@$paginator){
        $page = 1;
    }
    else{
        $page = 0;
    }
    $self->set_main('project_list.pl/main.tmpl');
    $self->template('main.tmpl', ['../tmpl/project_list.pl']);
    my %params = (closedloop => \@closedloop, page => $page, pageloop => $paginator, pageleft => $page_ref->{LEFT}, pageright => $page_ref->{RIGHT}, studentloop => $records_ref, name => $name);
    $self->output(%params);
}


1;
