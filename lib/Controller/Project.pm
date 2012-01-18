package Controller::Project;
use strict;
use warnings;
use base qw/Controller::Base/;
use Constants qw/TRUE/;
use FormValidator::Simple;
use Date::Calc qw/Today Delta_Days Add_Delta_Days/;
use Digest::MD5 qw/md5_base64/;

sub authenticate {
    my ($self) = @_;
    unless($self->cookie('psw') and ($self->cookie('psw') eq md5_base64('sdc'))){
        $self->redirect('project_password.pl');
        exit;
    }
}

sub _date_diff {
    return Delta_Days(@_);
}

sub calculate_logical_status {
    my ($kick_off, $quota) = @_;
    my @today = Today;
    my $days_remain = _date_diff(split('-', $kick_off), $today[0], $today[1], $today[2]);
    my @stages = qw/style_fix development codereview_sh codereview_jp qa_jp/;
    my %status = (style_fix => '式样fix', development => '开发', codereview_sh => 'sh审核', codereview_jp => 'jp审核', qa_jp => 'jp质检');
    if($days_remain >= 0){
        for my $stage (@stages){
            if($days_remain > $quota->{$stage}){
                $days_remain -= $quota->{$stage};
            }
            else{
                return $status{$stage};
            }
        }
        return '已结束';
    }
    else{
        return '尚未开始';
    }
}

sub modify_days_outlook {
    my ($self, $records) = @_;
    my @stages = qw/kick_off style_fix development codereview_sh codereview_jp qa_jp/;
    for my $record (@$records){
        for(my $i = 1; $i < @stages; $i++){
            $record->{$stages[$i]} = join('-', Add_Delta_Days(split('-', $record->{$stages[$i - 1]}), $record->{$stages[$i]})); 
        }
    }
}

sub blend_records {
    my ($self, $records) = @_;
    for(my $i = 0; $i < @$records; $i++){
        $records->[$i]{logic_status} = calculate_logical_status($records->[$i]{kick_off}, $records->[$i]); 
    }
}

1;
