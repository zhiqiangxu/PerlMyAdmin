package Controller::Student::Edit;
use strict;
use warnings;
use base qw/Controller::Base/;
use Model::Student;
use Model::Province;
use Model::City;
use Constants qw/TRUE FALSE/;
use CGI qw/header/;
use FormValidator::Simple;

sub validate {
    my ($self, $query) = @_;
    my $result = FormValidator::Simple->check( $query => [
        name => ['NOT_BLANK'],
        introduction => ['NOT_BLANK'],
        province_id => ['NOT_BLANK', 'UINT', ['GREATER_THAN', 0]],
        city_id => ['NOT_BLANK', 'UINT', ['GREATER_THAN', 0]],
        school => ['NOT_BLANK'],
        major => ['NOT_BLANK'],
        birthday => ['NOT_BLANK', ['DATETIME_STRPTIME','%Y-%m-%d']],
        gender => ['NOT_BLANK', ['IN_ARRAY', qw/0 1/]]
    ]);
    return ($result->has_error, $result);
}

sub dump_submit {
    my ($self) = @_;
    return {
            name => $self->param('name'), 
            no => $self->param('no'), 
            introduction => $self->param('no'), 
            province_id => $self->param('province_id'),
            city_id => $self->param('city_id'),
            school => $self->param('school'),
            major => $self->param('major'),
            birthday => $self->param('birthday'),
            gender => $self->param('gender')
    };
}

sub collect_error {
    my ($self, $result) = @_;
    my $error = '';
    foreach my $key ($result->error){
        foreach my $type ($result->error($key)){
            $error .= "<p>[$type] - [$key]</p>";
        }
    }
    return $error;
}

sub populate_select {
    my ($self, $row) = @_;
    my $province = Model::Province->new;
    my $result_province = $province->select_all;
    my $result_city;
    if($row->{province_id}){
        my $city = Model::City->new;
        $result_city = $city->of_province($row->{province_id});
        foreach my $record (@$result_province){
            $record->{selected} = TRUE if $record->{id} eq $row->{province_id};
        }
        if($row->{city_id}){
            foreach my $record (@$result_city){
                $record->{selected} = TRUE if $record->{id} eq $row->{city_id};
            }
        }
    }
    return ($result_province, $result_city);
}

sub display {
    my ($self) = @_;
    my ($message, $error, $submited_params);
    my $student = Model::Student->new;
    if('POST' eq $self->query->request_method){
        my ($fail, $result) = $self->validate($self->query);
        if($fail){
            $message = '参数有误';
            $error = 'Error Messages: ' . $self->collect_error($result);
            $submited_params = $self->dump_submit;
        }
        else{
            my ($columns_ref, $include) = ( {id => TRUE, no => TRUE}, FALSE );
            if($self->do_table_update('student', $columns_ref, $include, TRUE)){
                $message = '更新成功';
            }
            else{
                $message = '更新失败';
            }
       }
    }
    $self->redirect('student_list.pl') unless $self->url_param('id');
    my $row = $submited_params ? $submited_params : $student->query("SELECT * FROM student WHERE id=?", [$self->url_param('id')], TRUE);

    my ($result_province, $result_city) = $self->populate_select($row);
    $self->set_main('student_edit.pl/main.tmpl')->add_js('static/js/student_add.js');
    $self->template('main.tmpl', ['../tmpl/student_edit.pl']);
    $self->output(%$row, provinceloop => $result_province, cityloop => $result_city, message => $message, referrer => $self->param('referrer') ? $self->param('referrer') : $self->query->referer, error => $error);

}

1
