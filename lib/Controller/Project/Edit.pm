package Controller::Project::Edit;
use strict;
use warnings;
use base qw/Controller::Project/;
use Constants qw/TRUE/;
use FormValidator::Simple;
use Model::Student;
use Date::Calc qw/Today Delta_Days/;

sub validate {
    my ($self, $query) = @_;
    my $result = FormValidator::Simple->check( $query => [
        id => ['NOT_BLANK', 'UINT'],
        name => ['NOT_BLANK'],
        kick_off => ['NOT_BLANK', ['DATETIME_STRPTIME','%Y-%m-%d']],
        style_fix    => ['NOT_BLANK', 'UINT'],
        development => ['NOT_BLANK', 'UINT'],
        codereview_sh => ['NOT_BLANK', 'UINT'],
        codereview_jp => ['NOT_BLANK', 'UINT'],
        qa_jp => ['NOT_BLANK', 'UINT'],
        date_to_release => ['NOT_BLANK', ['DATETIME_STRPTIME','%Y-%m-%d']],
        developers => ['NOT_BLANK'],
        closed => ['UINT']
    ]);
    return ($result->has_error, $result);
}

sub dump_submit {
    my ($self) = @_;
    return {
            id => $self->param('id'),
            name => $self->param('name'), 
            kick_off => $self->param('kick_off'), 
            style_fix => $self->param('style_fix'), 
            development => $self->param('development'),
            codereview_sh => $self->param('codereview_sh'),
            codereview_jp => $self->param('codereview_jp'),
            qa_jp => $self->param('qa_jp'),
            date_to_release => $self->param('date_to_release'),
            status => $self->param('status'),
            notes => $self->param('notes'),
            developers => $self->param('developers'),
            closed => $self->param('closed')
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


sub display {
    my ($self) = @_; 
    my ($message, $error, $submited_params);
    if('POST' eq $self->query->request_method){
        $self->param('closed', 0) if($self->param('closed'));
        my ($fail, $result) = $self->validate($self->query);
        if($fail){
            $message = '参数有误';
            $error = 'Error Messages: ' . $self->collect_error($result);
            $submited_params = $self->dump_submit;
        }
        else{
            if($self->do_table_update('project', undef, undef, TRUE)){
                $self->redirect('/project_view.pl?id=' .  $self->param('id'));
                exit;
            }
            else{
                $submited_params = $self->dump_submit;
                $message = '项目名重复';
            }
        }
    }

    my $student = Model::Student->new;
    my $row = $submited_params ? $submited_params : $student->query("SELECT * FROM project WHERE id=?", [$self->url_param('id')], TRUE);
    $self->blend_records([$row]);
#set_main is useless for the weakness of Pro
    $self->set_main('project_edit.pl/main.tmpl');
    $self->template('main.tmpl', ['../tmpl/project_edit.pl']);
    my %params = (%$row, message => $message, error => $error, $submited_params ? %$submited_params : ());
    $self->output(%params);
}

1;
