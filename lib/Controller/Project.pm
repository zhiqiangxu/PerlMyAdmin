package Controller::Project;
use strict;
use warnings;
use base qw/Controller::Base/;
use Constants qw/TRUE USE_PSW/;
use FormValidator::Simple;
use Date::Calc qw/Today Delta_Days Add_Delta_Days Day_of_Week/;
use Digest::MD5 qw/md5_base64/;

sub authenticate {
    my ($self) = @_;
    unless($self->cookie('psw') and ($self->cookie('psw') eq md5_base64(USE_PSW))){
        $self->redirect('project_password.pl');
        exit;
    }
}

sub calculate_logical_status {
    my ($kick_off, $quota) = @_;
    my @today = Today;
    my $days_remain = Delta_Days(@today, split('-', $kick_off));
    my @stages = qw/style_fix development codereview_sh codereview_jp qa_jp/;
    my %status = (style_fix => '式样fix', development => '开发', codereview_sh => 'sh_cr', codereview_jp => 'jp_cr', qa_jp => 'jp_qa');
    if(0 == $days_remain){
        return ('kick_off', 'kick_off')
    }
    elsif($days_remain < 0){
        my @tmp_date = split('-', $kick_off);
        for my $stage (@stages){
            @tmp_date = add_delta_work_days(@tmp_date, $quota->{$stage});
            if(Delta_Days(@today, @tmp_date) >= 0){
                return ($status{$stage}, $stage);
            }
        }
        return '已结束';
    }
    else{
        return '尚未开始';
    }
}

#count week days only
sub add_delta_work_days {
    my ($year, $month, $day, $delta) = @_;
    my $n = 0;
    my @tmp_date = ($year, $month, $day);
    
    while($n < $delta){
        @tmp_date = Add_Delta_Days(@tmp_date, 1);
        unless(Day_of_Week(@tmp_date) > 5){
            $n ++;
        }
    }
    return @tmp_date;
}

sub _day_of_week {
    my ($date) = @_;
    my %week_days = (1 => '一', 2 => '二', 3 => '三', 4 => '四', 5 => '五', 6 => '六', 7 => '日');
    eval {
        return $week_days{Day_of_Week(split('-', $date))};
    };
}

sub modify_days_outlook {
    my ($self, $records) = @_;
    my @stages = qw/kick_off style_fix development codereview_sh codereview_jp qa_jp/;
    for my $record (@$records){
        $record->{kick_off_bak_date} = $record->{kick_off};
        for(my $i = 1; $i < @stages; $i++){
            $record->{$stages[$i] . '_bak'} = $record->{$stages[$i]};
            unless($record->{$stages[$i] . '_bak'}){
                $record->{$stages[$i]} = '--';
                $record->{$stages[$i] . '_bak_date'} = $record->{$stages[$i - 1] . '_bak_date'};
                next;
            }
            $record->{$stages[$i]} = join('-', add_delta_work_days(split('-', $record->{$stages[$i - 1]}), $record->{$stages[$i]})); 
            $record->{$stages[$i] . '_bak_date'} = $record->{$stages[$i]};
        }
        for(my $i = 1; $i < @stages; $i++){
            unless($record->{$stages[$i] . '_bak'}){
                next;
            }
            $record->{$stages[$i]} = $record->{$stages[$i] . '_bak'} . 'd<br />' 
                                     . join('-', add_delta_work_days(split('-', $record->{$stages[$i - 1] . '_bak_date'}), 1))
                                     . '<br />(' . _day_of_week(join('-', add_delta_work_days(split('-', $record->{$stages[$i - 1] . '_bak_date'}), 1))) . ')'
                                     . '<br />至<br />'
                                     . $record->{$stages[$i]} 
                                     . '<br />(' . _day_of_week($record->{$stages[$i]}) . ')';
        }
        eval {
            $record->{kick_off} .= '<br />(' . _day_of_week($record->{kick_off}). ')';
            $record->{date_to_release} .= '<br />(' . _day_of_week($record->{date_to_release}) if $record->{date_to_release};
        };
    }
}

sub blend_records {
    my ($self, $records) = @_;
    my @result;
    my $tmp_key;
    for(my $i = 0; $i < @$records; $i++){
        @result= calculate_logical_status($records->[$i]{kick_off}, $records->[$i]);
        $records->[$i]{logic_status} = $result[0];
        if(exists $result[1]){
            $tmp_key = 'high_light_' . $result[1];
            $records->[$i]{$tmp_key} = 1;
        }
    }
}

1;
