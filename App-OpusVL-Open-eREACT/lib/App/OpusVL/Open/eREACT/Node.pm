package App::OpusVL::Open::eREACT::Node;

=head1 NAME

App::OpusVL::Open::eREACT::Command::Node - Primary engine

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

# Internal modules (dist)


# External modules
use POE qw(Filter::Reference Wheel::ReadWrite Component::FunctionNet);
use Carp;
use Acme::CommandCommon;

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
            $self => [qw(
                _start
                _loop
                _stop
                com
            )]
        ],
        heap            =>  {
            common          =>  Acme::CommandCommon->new(1),
        }
    );

    $self->{id} = $self->{session}->ID;

    return $self;  
}

sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    my $functionNetConfig       =   {
        mode    =>  'plugin',
        handler =>  'com'
    };

    $heap->{functionnet}->{obj} =
        POE::Component::FunctionNet->new($functionNetConfig);

    $heap->{stash}->{start_time}    =   time;
    $heap->{stash}->{latency}       =   time;

    $kernel->yield('_loop');
}

sub _loop {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    my $latency = (time - $heap->{stash}->{latency});

    if ($latency > 10) {
        say STDERR "Parent<->Child Latency exceeded 10 seconds, exiting.";
        exit 1;
    }

    say '_loop';

    #$heap->{com}->ping(time);

    $kernel->delay_add('_loop' => 1,time);
}

sub _stop {
}

sub com {
    my ($kernel,$heap,$session,$sender,$data) = 
        @_[KERNEL,HEAP,SESSION,SENDER,ARG0];

    warn "COM CALLED";
}


1;
