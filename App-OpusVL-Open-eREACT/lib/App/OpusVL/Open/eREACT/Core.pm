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
use POE;

# Version of this software
our $VERSION = '0.001';

sub new {
    my ($class,$args) = @_;

    use Data::Dumper;
    warn Dumper($args);

    my $self = bless {
        alias   => __PACKAGE__,
        session => 0,
    }, $class;

    $self->{session} = POE::Session->create(
        object_states => [
            $self => ['_start','_loop','_stop']
        ]
    );

    $self->{id} = $self->{session}->ID;

    return $self;  
}


sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    $heap->{counter} = 0;
    $kernel->yield('_loop');
}

sub _loop {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    if ($heap->{counter}++ >= 10) {
        say "That's all folks.";
        $kernel->yield('shutdown');
    }
    else {
        say "tick";
        $kernel->delay_add('_loop' => 1);
    }
}

sub _stop {
    say "_stop called";
}

1;
