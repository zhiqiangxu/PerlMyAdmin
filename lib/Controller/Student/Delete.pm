package Controller::Student::Delete;
use strict;
use warnings;
use base qw/Controller::Base/;
use Model::Student;
use Model::Province;
use Model::City;
use Constants qw/TRUE FALSE/;
use CGI qw/header/;

sub display {
    my ($self) = @_;
    my $student = Model::Student->new;
    my $message;
    if('POST' eq $self->query->request_method){
        if($self->do_table_delete('student', TRUE)){
            $self->redirect($self->generate_uri({random =>  rand()}, 'student_list.pl'));
            exit;
        }
        else{
            $message = '删除失败';
        }
    }

    my $row = $student->query("SELECT * FROM student WHERE id=?", [$self->url_param('id')], TRUE);
    if($row->{province_id}){
        my $province = Model::Province->new;
        my $result = $province->query("SELECT * FROM province WHERE id=?", [$row->{province_id}], TRUE);
        $row->{province} = $result->{name};
    }
    if($row->{city_id}){
        my $city = Model::Province->new;
        my $result = $city->query("SELECT * FROM city WHERE id=?", [$row->{city_id}], TRUE);
        $row->{city} = $result->{name};
    }
    $self->set_main('student_delete.pl/main.tmpl')->add_js('static/js/student_add.js');
    $self->template('main.tmpl', ['../tmpl/student_delete.pl']);
    $self->output(%$row, message => $message);

}

1
