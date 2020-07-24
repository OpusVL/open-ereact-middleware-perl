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
use POE qw(Wheel::Run Component::FunctionNet::Interface);
use Carp;
use Acme::CommandCommon;

# Version of this software
our $VERSION = '0.001';

sub new {
    my ($class) = @_;

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
            )]
        ],
        heap            =>  {}
    );

    $self->{id} = $self->{session}->ID;

    return $self;
}

sub _start {
    my ($kernel,$heap,$session) = @_[KERNEL,HEAP,SESSION];

    $heap->{functionnet} = POE::Component::FunctionNet::Interface->new();

    # We now can make object calls to FunctionNet
    # Tell this function net it will be the controller of the network
    $heap->{functionnet}->load([
        'perl',
        '/home/paul.webster/Work/Project-DigiMiddleware/open-ereact-middleware-perl/plugins/plan.pl'
    ]);

    # Start the 'plan' controller
    $kernel->yield('_loop');
}

sub _loop {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    $kernel->delay_add('_loop' => 1);
}

sub _stop {
    say "_stop called";
}

1;
