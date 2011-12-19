package Controller::Student::List;
use strict;
use warnings;
use base qw/Controller::Base/;
use Model::Student;
use Constants qw/TRUE/;
use CGI qw/header/;
use POSIX;

sub get_city_and_province {
    my ($self, $model, $city_id_list, $province_id_list) = @_;
    my $cities = $model->query("SELECT * FROM city WHERE id IN ($city_id_list)");
    my (%result_city, %result_province);
    foreach my $record (@$cities){
        $result_city{$record->{id}} = $record->{name};
    }
    my $provinces = $model->query("SELECT * FROM province WHERE id IN ($province_id_list)");
    foreach my $record (@$provinces){
        $result_province{$record->{id}} = $record->{name};
    }
    return (\%result_city, \%result_province);
}

sub update_records {
    my ($self, $model, $records_ref) = @_;
    my ($city_id_list, $province_id_list);
    foreach my $record (@$records_ref){
        $city_id_list .= ',' . $record->{city_id} if $record->{city_id};
        $province_id_list .= ',' . $record->{province_id} if $record->{province_id};
    }
    ($city_id_list, $province_id_list) = (substr($city_id_list, 1), substr($province_id_list, 1));
    my ($city_ref, $province_ref) = $self->get_city_and_province($model, $city_id_list, $province_id_list);
    foreach my $record (@$records_ref){
        $record->{city} = $city_ref->{$record->{city_id}};
        $record->{province} = $province_ref->{$record->{province_id}};
        $record->{gender_literal} = $record->{gender} ? '男' : '女';
    }
}

sub populate_select {
    my ($self, $model, $province_id, $city_id) = @_;
    my ($provinces, $cities);
    $provinces = $model->query("SELECT * FROM province");
    if($province_id gt 0){
        $cities = $model->query("SELECT * FROM city WHERE province_id=?", [$province_id]);
        foreach my $record (@$provinces){
            if($record->{id} eq $province_id){
                $record->{selected} = TRUE;
            }
        }
        if($city_id gt 0){
            foreach my $record (@$cities){
                if($record->{id} eq $city_id){
                    $record->{selected} = TRUE;
                }
            }
        }
    }
    return ($provinces, $cities);
}

sub generate_filter {
    my ($self, $province_id, $city_id, $keyword) = @_;
    my $where = '';
    my @bindings;
    if($province_id gt 0){
        $where .= 'AND province_id=?';
        push @bindings, $province_id;
    }
    if($city_id gt 0){
        $where .= 'AND city_id=?';
        push @bindings, $city_id;
    }
    if($keyword or $keyword eq '0'){
        $where .= 'AND (school LIKE ?  OR major LIKE ? OR name LIKE ?)';
        push @bindings, '%' . $keyword . '%';
        push @bindings, '%' . $keyword . '%';
        push @bindings, '%' . $keyword . '%';
    }
    if($where){
        $where = 'WHERE ' . substr($where, 4); 
    }
    return {where => $where, bindings => \@bindings};
}

sub display {
    my ($self) = @_;
    my ($page, $keyword) = ($self->param('page') ? $self->param('page') : 1, $self->param('keyword'));
    my $student = Model::Student->new;
    my $result = $self->do_table_select('student', TRUE, $self->generate_filter($self->param('province_id'), $self->param('city_id'), $self->param('keyword')));
    my ($page_ref, $records_ref) = ($result->{page_ref}, $result->{records_ref}); 
    $self->update_records($student, $records_ref);
    my ($provinces, $cities) = $self->populate_select($student, $self->param('province_id'), $self->param('city_id'));

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
    $self->set_main('student_list.pl/main.tmpl')->add_js('static/js/student_add.js')->add_js('static/js/student_list.js');
    $self->template('main.tmpl', ['../tmpl/student_list.pl']);
    my %params = (pageloop => $paginator, pageleft => $page_ref->{LEFT}, pageright => $page_ref->{RIGHT}, studentloop => $records_ref, provinceloop => $provinces, cityloop => $cities, keyword => $keyword);
    $self->output(%params);
}

1
