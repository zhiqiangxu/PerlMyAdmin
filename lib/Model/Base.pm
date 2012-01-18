package Model::Base;
use strict;
use warnings;
use DBI;
use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors(qw/dbh/);
use Configuration qw/DSN DB_USER DB_PASS/;



sub new {
    my ($class, %args) = @_;
    return bless {dbh => undef, %args}, $class;
}

sub initDBH {
    my ($self, %args) = @_;
    $self->dbh(DBI->connect(DSN, DB_USER, DB_PASS, { RaiseError => 0 }));
$self->execute("SET NAMES UTF8");
}

sub parse_where {
    my ($self, $args, $bindings) = @_;
    $bindings ||= [];
    my $where = '';
    while(my($key, $value) = each(%$args)){
        if('HASH' eq ref $value){
            $where .= " $key (" . $self->parse_where($value, $bindings) . ")";
        }
        elsif('ARRAY' eq ref $value){
            $where .= " $key (";
            my $sequence = '';
            foreach my $v (@$value){
                $sequence .= ',?';
                push @$bindings, $v;
            }
            if($sequence){
                $sequence = substr($sequence, 1);
            }
            $where .= $sequence . ")";
        }
        else{
            $where .= " $key?";
            push @$bindings, $value;
        }
    }
    if($where){
        $where = "WHERE $where";
    }
    return ($where, $bindings);
}

sub select {
    my ($self, $table, $args) = @_;
    $self->initDBH unless $self->dbh;
    my ($where, $bindings) = $self->parse_where($args);
    my $sql = "SELECT * FROM $table $where";
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@$bindings);
    $sth->fetchrow_hashref;
}

sub selectList {
    my ($self, $table, $args) = @_;
    $self->initDBH unless $self->dbh;
    my ($where, $bindings) = $self->parse_where($args);
    my $sql = "SELECT * FROM $table $where";
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@$bindings);
    $sth->fetchall_arrayref({});
}

sub update {
    my ($self, %args) = @_;
    $self->initDBH unless $self->dbh;
}

sub insert {
    my ($self, %args) = @_;
    $self->initDBH unless $self->dbh;
}

sub delete {
    my ($self, %args) = @_;
    $self->initDBH unless $self->dbh;
}

sub execute {
    my ($self, $sql, @bindings) = @_;
    $self->initDBH unless $self->dbh;
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@bindings);
}

sub query {
    my ($self, $sql, $bindings, $return_one) = @_;
    $self->initDBH unless $self->dbh;
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@{$bindings});
    if($return_one){
        $sth->fetchrow_hashref;
    }
    else{
        $sth->fetchall_arrayref({});
    }
}

sub last_insert_id {
    my ($self) = @_;
    return unless $self->dbh;
    return $self->dbh->{mysql_insertid};
}

1
