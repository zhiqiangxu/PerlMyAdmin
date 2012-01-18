package Controller::Project::Auth;
use strict;
use warnings;
use base qw/Controller::Project/;
use Constants qw/TRUE USE_PSW/;
use FormValidator::Simple;
use Digest::MD5 qw/md5_base64/;

sub display {
    my ($self) = @_; 
    my ($message);
    if('POST' eq $self->query->request_method){
        if($self->param('psw') && md5_base64(USE_PSW) eq md5_base64($self->param('psw'))){
            $self->cookie(psw => md5_base64(USE_PSW));
            $self->redirect('project_list.pl');
            exit;
        }
        else{
            $message = '密码错误';
        }
    }
    $self->set_main('project_password.pl/main.tmpl');
    $self->template('main.tmpl', ['../tmpl/project_password.pl']);
    my %params = (message => $message, psw => $self->param('psw'));
    $self->output(%params);
}

1;
