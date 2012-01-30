package Controller::Scaffold;
use strict;
use warnings;
use Model::Base;
use Constants qw/DB_NAME/;
use CGI qw/header/;
use Constants qw/TRUE/;
use base qw/Controller::ProFix/;
use POSIX;

sub display {
    my ($self) = @_;
    no strict 'refs';
    if($self->url_param('for')){
        if(!$self->url_param('model') && 'left' eq $self->url_param('for')){
            $self->list_tables;
        }
        elsif($self->url_param('model')){
            my $action = $self->url_param('action') ? $self->url_param('action') : 'select';
            no strict 'refs';
            &{"do_table_$action"}($self, $self->url_param('model'));
        }
    }
    else{
        $self->layout;
    }
    $self->output;
}



sub layout {
    my ($self) = @_;
    $self->template('layout.tmpl', ['../tmpl' . $self->query->script_name]);
}

sub list_tables {
    my ($self) = @_;
    my $model = Model::Base->new;
    $self->template('list_tables.tmpl', ['../tmpl' . $self->query->script_name])->param(tableloop => $model->query("SELECT table_name FROM information_schema.tables WHERE table_schema = DATABASE()"));
}

sub do_table_select {
    my ($self, $model_name, $return, $filter) = @_;
    my ($where, $bindings) = $filter ? ($filter->{where}, $filter->{bindings}) : ('', []);
    my $model = Model::Base->new;
    my $page = $self->param('page') ? $self->param('page') : 1;
    my $per_page = $self->param('per_page') ? $self->param('per_page') : 20;
    my $records_ref = $model->query("SELECT * FROM $model_name $where LIMIT ${\(($page - 1) * $per_page)},$per_page", $bindings);
    my $total_ref = $model->query("SELECT COUNT(*) total FROM $model_name $where", $bindings, TRUE);
    my $page_ref = $self->paginator($page, ceil($total_ref->{total}/$per_page), 5);

    return {records_ref => $records_ref, page_ref => $page_ref} if $return;

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
    my $pk_ref = $model->query("SHOW INDEX FROM $model_name WHERE Key_name='PRIMARY'", undef, TRUE);
    $self->template('table_select.tmpl', ['../tmpl' . $self->query->script_name])->param(header => $self->html_new($model_name), rows => $self->rows_to_html($records_ref, $pk_ref->{Column_name}),pageloop => $paginator, pageleft => $page_ref->{LEFT}, pageright => $page_ref->{RIGHT});

}

sub do_table_before_delete {
    my ($self, $model_name) = @_;
    my $model = Model::Base->new;
    my $pk_ref = $model->query("SHOW INDEX FROM $model_name WHERE Key_name='PRIMARY'", undef, TRUE);
    my $record_ref = $model->query("SELECT * FROM $model_name WHERE $pk_ref->{Column_name}=" . $self->param($pk_ref->{Column_name}), undef, TRUE);
    $self->template('table_delete.tmpl', ['../tmpl' . $self->query->script_name])->param(whole => $self->row_to_literal_html($record_ref, $pk_ref->{Column_name}, $model_name));
}


sub do_table_delete {
    my ($self, $model_name, $return) = @_;
    my $model = Model::Base->new;
    my $pk_ref = $model->query("SHOW INDEX FROM $model_name WHERE Key_name='PRIMARY'", undef, TRUE);
    my $column_info = $model->query("SHOW COLUMNS FROM $model_name");
    my @columns = ($pk_ref->{Column_name});
    my @bindings = ();
    my %params = ($pk_ref->{Column_name} => $self->param($pk_ref->{Column_name}));
    my $binding_string = $self->prepare_update_binding_string(\@columns, \%params, \@bindings);
    my $dml = "DELETE FROM $model_name WHERE $binding_string";
    my $result = $model->execute($dml, @bindings);

    return $result if $return;

    unless(defined $result){
        my $msg = "Believe or not, IT JUST FAILED!";
#this is done mainly to keep the order of columns in the form
        my $record_ref = $model->query("SELECT * FROM $model_name WHERE $pk_ref->{Column_name}=" . $self->param($pk_ref->{Column_name}), undef, TRUE);
        while (my ($k, $v) = each(%{$record_ref})){
            $record_ref->{$k} = $self->param($k);
        }
        $self->template('table_delete.tmpl', ['../tmpl' . $self->query->script_name])->param(message => $msg, whole => $self->row_to_literal_html($record_ref, $pk_ref->{Column_name}, $model_name));
    }
    else{
        $self->redirect($self->generate_uri({random =>  rand()}, $self->param('referrer')));
    }
}

sub do_table_before_update {
    my ($self, $model_name) = @_;
    my $model = Model::Base->new;
    my $pk_ref = $model->query("SHOW INDEX FROM $model_name WHERE Key_name='PRIMARY'", undef, TRUE);
    my $record_ref = $model->query("SELECT * FROM $model_name WHERE $pk_ref->{Column_name}=" . $self->param($pk_ref->{Column_name}), undef, TRUE);
    $self->template('table_update.tmpl', ['../tmpl' . $self->query->script_name])->param(whole => $self->row_to_html($record_ref, $pk_ref->{Column_name}, $model_name));
}

sub do_table_update {
    my ($self, $model_name, $columns_ref, $include, $return) = @_;
    my $model = Model::Base->new;
    my $pk_ref = $model->query("SHOW INDEX FROM $model_name WHERE Key_name='PRIMARY'", undef, TRUE);
    my $column_info = $model->query("SHOW COLUMNS FROM $model_name");
    my @columns = ();
    my @bindings = ();
    my %params = ();
    foreach my $item (@{$column_info}){
        if($pk_ref->{Column_name} ne $item->{Field}){
            do {
                push @columns, $item->{Field};
                $params{$item->{Field}} = $self->param($item->{Field});
            } unless($columns_ref and ( ($include and (! exists $columns_ref->{$item->{Field}})) or (!$include and (exists $columns_ref->{$item->{Field}})) ));
        }
    }
    my $binding_string = $self->prepare_update_binding_string(\@columns, \%params, \@bindings);
    push @bindings, $self->param($pk_ref->{Column_name});
    my $dml = "UPDATE $model_name SET $binding_string WHERE $pk_ref->{Column_name}=? LIMIT 1";
    my $result = $model->execute($dml, @bindings);

    return $result if $return;

    unless(defined $result){
        my $msg = "Invalid value!";
#this is done mainly to keep the order of columns in the form
        my $record_ref = $model->query("SELECT * FROM $model_name WHERE $pk_ref->{Column_name}=" . $self->param($pk_ref->{Column_name}), undef, TRUE);
        while (my ($k, $v) = each(%{$record_ref})){
            $record_ref->{$k} = $self->param($k);
        }
        $self->template('table_update.tmpl', ['../tmpl' . $self->query->script_name])->param(message => $msg, whole => $self->row_to_html($record_ref, $pk_ref->{Column_name}, $model_name));
    }
    else{
        $self->redirect($self->generate_uri({random =>  rand()}, $self->param('referrer')));
    }
}

sub do_table_before_insert {
    my ($self, $model_name) = @_;
    my $model = Model::Base->new;
    my $pk_ref = $model->query("SHOW INDEX FROM $model_name WHERE Key_name='PRIMARY'", undef, TRUE);
    my $column_info = $model->query("SHOW COLUMNS FROM $model_name");
    my $record_layout = {};
    foreach my $item (@{$column_info}){
        $record_layout->{$item->{Field}} = undef;
    }
    $self->template('table_insert.tmpl', ['../tmpl' . $self->query->script_name])->param(whole => $self->empty_row_to_html($record_layout, $pk_ref->{Column_name}, $model_name));
}

sub do_table_insert {
    my ($self, $model_name, $return) = @_;
    my $model = Model::Base->new;
    my $pk_ref = $model->query("SHOW INDEX FROM $model_name WHERE Key_name='PRIMARY'", undef, TRUE);
    my $column_info = $model->query("SHOW COLUMNS FROM $model_name");
    my @columns = ();
    my @bindings = ();
    my %params = ();
    foreach my $item (@{$column_info}){
        if($pk_ref->{Column_name} ne $item->{Field}){
            push @columns, $item->{Field};
            $params{$item->{Field}} = $self->param($item->{Field});
        }
    }
    my $binding_string = $self->prepare_insert_binding_string(\@columns, \%params, \@bindings);
    push @bindings, $self->param($pk_ref->{Column_name});
    my $dml = "INSERT INTO $model_name $binding_string";

    my $result = $model->execute($dml, @bindings);
    return $result ? $model->last_insert_id : $result if $return;

    unless(defined $result){
        my $msg = "Invalid value!";
#this is done mainly to keep the order of columns in the form
        my $record_ref = $model->query("SELECT * FROM $model_name WHERE $pk_ref->{Column_name}=" . $self->param($pk_ref->{Column_name}), undef, TRUE);
        while (my ($k, $v) = each(%{$record_ref})){
            $record_ref->{$k} = $self->param($k);
        }
        $self->template('table_insert.tmpl', ['../tmpl' . $self->query->script_name])->param(message => $msg, whole => $self->empty_row_to_html($record_ref, $pk_ref->{Column_name}, $model_name));
    }
    else{
        $self->redirect($self->generate_uri({random =>  rand()}, $self->param('referrer')));
    }
}
1
