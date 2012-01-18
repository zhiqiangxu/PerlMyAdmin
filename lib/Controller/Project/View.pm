package Controller::Project::View;
use strict;
use warnings;
use base qw/Controller::Project/;
use Constants qw/TRUE FALSE/;
use CGI qw/header/;
use Model::Student;
use FormValidator::Simple;
use Date::Calc qw/Today Delta_Days/;


sub display {
    my ($self) = @_;
    $self->authenticate;
    my ($message, $error, $submited_params);
    my $student = Model::Student->new;
    $self->redirect('project_list.pl') unless $self->url_param('id');
    my $row = $student->query("SELECT * FROM project WHERE id=?", [$self->url_param('id')], TRUE);
    $self->redirect('project_list.pl') unless $row;
    $self->blend_records([$row]);
    $self->modify_days_outlook([$row]);
    $self->redirect('project_list.pl') unless $row;
    $self->set_main('student_view.pl/main.tmpl');
    $self->template('main.tmpl', ['../tmpl/project_view.pl']);
    $self->output(%$row, referrer => $self->param('referrer') ? $self->param('referrer') : $self->query->referer);
}

1
