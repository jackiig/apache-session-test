package Apache::Session::MySQL;
use strict;
use vars qw(@ISA $VERSION);
use Data::Dumper;

$VERSION = '1.01';
@ISA = qw(Apache::Session);

use Apache::Session;
use Apache::Session::Lock::MySQL;
use Apache::Session::Store::MySQL;
use Apache::Session::Generate::UUID;
use Apache::Session::Serialize::Storable;

warn Dumper("Loading custom Apache::Session::MySQL");

sub populate {
  my $self = shift;

  $self->{object_store} = new Apache::Session::Store::MySQL $self;
  $self->{lock_manager} = new Apache::Session::Lock::MySQL $self;
  $self->{generate}     = \&Apache::Session::Generate::UUID::generate;
  $self->{validate}     = \&Apache::Session::Generate::UUID::validate;
  $self->{serialize}    = \&Apache::Session::Serialize::Storable::serialize;
  $self->{unserialize}  = \&Apache::Session::Serialize::Storable::unserialize;

  return $self;
}

1;
