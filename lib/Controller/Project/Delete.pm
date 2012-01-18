package Controller::Project::Delete;
use strict;
use warnings;
use base qw/Controller::Project/;
use Model::Student;
use Model::Province;
use Model::City;
use Constants qw/TRUE FALSE DELETE_PSW/;
use CGI qw/header/;
use Date::Calc qw/Today Delta_Days/;


sub display {
    my ($self) = @_;
    $self->authenticate;
    my $student = Model::Student->new;
    my $message;
    if('POST' eq $self->query->request_method){
        if(DELETE_PSW ne $self->param('psw')){
            $message = '密码错误';
        }
        elsif($self->do_table_delete('project', TRUE)){
            $self->redirect($self->generate_uri({random =>  rand()}, 'project_list.pl'));
            exit;
        }
        else{
            $message = '删除失败';
        }
    }

    my $row = $student->query("SELECT * FROM project WHERE id=?", [$self->url_param('id')], TRUE);
    $self->blend_records([$row]);
    $self->modify_days_outlook([$row]);
    $self->set_main('project_delete.pl/main.tmpl');
    $self->template('main.tmpl', ['../tmpl/project_delete.pl']);
    $self->output($self->param('psw') ? (psw => $self->param('psw')) : (), %$row, message => $message, referrer => $self->param('referrer') ? $self->param('referrer') : $self->query->referer);

}

1
