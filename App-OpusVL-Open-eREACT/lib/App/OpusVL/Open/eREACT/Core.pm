package App::OpusVL::Open::eREACT::Core;


=head1 NAME

App::OpusVL::Open::eREACT::Command::Core - Primary engine

=cut

# Internal perl (move to 5.32.0)
use v5.30.0;
use feature 'say';

# Internal perl modules (core)
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use experimental qw(signatures);

# External modules
use POE qw(Wheel::Run Filter::Reference);
use Carp;
use Magnum::OpusVL::CommandCommon;

# Version of this software
our $VERSION = '0.001';

sub new {
    my ($class,$bind_ip,$bind_port) = @_;

    my $self = bless {
        alias   => __PACKAGE__,
        session => 0,
    }, $class;

    $self->{session} = POE::Session->create(
        object_states   => [
            $self => [qw(_start _loop _stop)]
        ],
        heap            =>  {
            common          =>  Magnum::OpusVL::CommandCommon->new(1),
            config          =>  {
                bind_ip         =>  $bind_ip,
                bind_port       =>  $bind_port
            }
        }
    );

    $self->{id} = $self->{session}->ID;

    return $self;  
}


sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];


}

sub _loop {
    my ($kernel,$heap) = @_[KERNEL,HEAP];


}

sub _stop {
    say "_stop called";
}

1;
