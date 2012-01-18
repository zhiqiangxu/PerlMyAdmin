package Controller::Base;
use strict;
use warnings;
use CGI qw/header/;
use CGI::Cookie;
use base qw/Class::Accessor::Fast Controller::Page Controller::Scaffold/;
__PACKAGE__->mk_accessors(qw/query tmpl/);
use URI qw//;
use URI::QueryParam qw//;
use JSON::Any;
use HTML::Template::Pro;


sub new {
    my ($class,%args)=@_;
    return bless {TMPL_MAIN => undef, jsloop => [], query => exists $args{query} ? $args{query} : CGI->new, tmpl => undef, cookie => [], log_file => '../log.txt', %args}, $class;
}

sub redirect {
    my ($self, $uri) = @_;
    if($self->{cookie}){
        print $self->query->redirect( -url => $uri, -cookie => $self->{cookie});
    }
    else{
        print $self->query->redirect( $uri);
    }
}

sub template {
    my ($self, $file, $path, $filter) = @_;
    if($file){
        $self->tmpl( HTML::Template::Pro->new(filename=>$file, path => $path ? $path : ['../tmpl']), $filter ? ( filter => $filter ) : () );
    }
    else {
        $self->tmpl;
    }
}

sub cookie {
    my ($self, @args) = @_;
    if(0 == @args){
        #fetch all
        return CGI::Cookie->fetch;
    }
    elsif(1 == @args){
        #fetch one
        my %cookies = CGI::Cookie->fetch;
        return %cookies && exists $cookies{$args[0]} ? $cookies{$args[0]}->value : undef;
    }
    elsif(2 == @args){
        #set one
        my $cookie = CGI::Cookie->new(-name => $args[0], -value => $args[1]);
        push @{$self->{cookie}}, $cookie;
        return;
    }
    die "error usage of sub cookie";
}

sub generate_uri {
    my ($self, $params, $base) = @_;
#    $base = $self->query->self_url unless $base;
#    $base = $base or $self->query->self_url;
    $base = $base || $self->query->self_url;
    my $u = URI->new($base);
    while( my($k, $v) = each (%{$params})){
        $u->query_param($k => $v);
    }
    $u->as_string;
}

sub param {
    my $self = shift;
    return $self->query->param(@_);
}

sub url_param {
    my ($self, $key) = @_;
    return $self->query->url_param($key);
}

sub set_main {
    my ($self, $main) = @_;
    $self->{TMPL_MAIN} = $main;
    $self;
}

sub add_js {
    my ($self, $js) = @_;
    push @{$self->{jsloop}}, {f => $js};
    $self;
}

sub output {
    my ($self, %args) = @_;
    print header(-type => 'text/html', -charset => 'utf8', -cookie => $self->{cookie});
    if(!$self->template){
        $self->template('layout.tmpl', ['../tmpl']);
        exit;
    }
    $self->template->param(jsloop => $self->{jsloop},%args);
    print $self->template->output;
}

sub output_json{
    my ($self, $data) = @_;
    print header(-type=>'application/json',-charset=>'utf8');
    $ENV{JSON_ANY_CONFIG} = 'utf8=1';
    print JSON::Any->new->objToJson($data);
}

sub log {
    my ($self, $msg) = @_;
    open(local *LOG, '>>', $self->{log_file});
    print LOG $msg . $/;
    close LOG;
}

sub prepare_select_binding_string {
    goto &prepare_update_binding_string;
}

sub prepare_insert_binding_string {
    my ($self, $columns_ref, $hash_ref, $bindings_ref) = @_;
    my ($columns_string, $binding_string);
    $columns_string = $binding_string = '';
    foreach my $column (@{$columns_ref}){
        $columns_string .= ",$column";
        $binding_string .= ',?';
        push @{$bindings_ref}, $hash_ref->{$column};
    }
    my $result_string = '(' . substr($columns_string, 1) . ') VALUE(' . substr($binding_string, 1) . ')'; 
    return $result_string;
}

sub prepare_update_binding_string {
    my ($self, $columns_ref, $hash_ref, $bindings_ref) = @_;
    my $string = '';
    foreach my $column (@{$columns_ref}){
        $string .= ",$column=?";
        push @{$bindings_ref}, $hash_ref->{$column};
    }
    return substr($string, 1);
}

1
