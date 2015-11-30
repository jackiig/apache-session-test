package Apache::Session::Lock::MySQL;

use strict;

use DBI;
use vars qw($VERSION);
use Data::Dumper;
warn Dumper($$, "Loading custom Apache::Session::Lock::MySQL");

$VERSION = '1.01';

sub new {
    my $class = shift;

    return bless {lock => 0, lockid => undef, dbh => undef, mine => 0}, $class;
}

sub acquire_read_lock  {
    my $self    = shift;
    my $session = shift;

    return if $self->{lock};

    if (!defined $self->{dbh}) {
        if (defined $session->{args}->{LockHandle}) {
            $self->{dbh} = $session->{args}->{LockHandle};
        }
        else {
            $self->{dbh} = DBI->connect(
                $session->{args}->{LockDataSource},
                $session->{args}->{LockUserName},
                $session->{args}->{LockPassword},
                { RaiseError => 1, AutoCommit => 1 }
            );
            $self->{mine} = 1;
        }
    }

    local $self->{dbh}->{RaiseError} = 1;

    $self->{lockid} = "Apache-Session-$session->{data}->{_session_id}";

    #MySQL requires a timeout on the lock operation.  There is no option
    #to simply wait forever.  So we'll wait for a hour.

    my $sth = $self->{dbh}->prepare_cached(q{SELECT GET_LOCK(?, 10)}, {}, 1);
    warn Dumper([$$, "Getting lock for ID", $self->{lockid}]);
    my $return = $sth->execute($self->{lockid})
      or die($self->{dbh}->errstr);
    warn Dumper([$$, "Got lock for ID", $self->{lockid}, $return, ($return >= 1)]);
    unless ($return >= 1) {
      die(
        Dumper(
          "Unable to get MySQL Session Lock:",
          $DBI::errstr,
          $self->{dbh}->errstr,
        )
      );
    }
    $sth->finish();

    $self->{lock} = 1;
}

sub acquire_write_lock {
    $_[0]->acquire_read_lock($_[1]);
}

sub release_read_lock {
    my $self = shift;

    if ($self->{lock}) {
        local $self->{dbh}->{RaiseError} = 1;

        my $sth = $self->{dbh}->prepare_cached(q{SELECT RELEASE_LOCK(?)}, {}, 1);
        warn Dumper([$$, "Releasing lock for ID", $self->{lockid}]);
        my $return = $sth->execute($self->{lockid});
        warn Dumper([$$, "Done releasing lock for ID", $self->{lockid}, $return]);
        $sth->finish();

        $self->{lock} = 0;
    }
}

sub release_write_lock {
    $_[0]->release_read_lock;
}

sub release_all_locks  {
    $_[0]->release_read_lock;
}

sub DESTROY {
    my $self = shift;

    $self->release_all_locks;

    if ($self->{mine}) {
        $self->{dbh}->disconnect;
    }
}

1;
