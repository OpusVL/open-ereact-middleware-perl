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
use POE qw(Wheel::Run Filter::Reference Component::FunctionNet);
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
            com             =>  POE::Component::FunctionNet::Protocol->new(),
            config          =>  {
                bind_ip         =>  $bind_ip,
                bind_port       =>  $bind_port,
                tasks           =>  {}
            },
            stash           =>  {
                workerid    =>  1,
            }
        }
    );

    $self->{id} = $self->{session}->ID;

    return $self;
}


sub _start {
    my ($kernel,$heap,$session) = @_[KERNEL,HEAP,SESSION];

    $heap->{stash}->{filter_ref} =
        POE::Filter::Reference->new(Serializer => 'Storable');

    my $functionNetConfig       =   {
        mode    =>  'master',
        master  =>  $session->ID,
        handler =>  'com'
    };

    $heap->{functionnet}->{obj} = 
        POE::Component::FunctionNet->new($functionNetConfig);

    $kernel->yield(
        '_send',
        {
            command =>  'HELO',
            id      =>  $session->ID
        }
    );

    # Start the 'plan' controller

    $kernel->yield('_loop');
}

sub com {
    my ($kernel,$heap,$session,$sender,$data) = 
        @_[KERNEL,HEAP,SESSION,SENDER,ARG0];

    if ($data->{command} eq 'HELO') {
        $kernel->yield(
            '_send',
            {
                command =>  'LOAD',
                module  =>  'PLAN'
            }
        );
    }
}

sub _send {
    my ($kernel,$heap,$session,$packet) = @_[KERNEL,HEAP,SESSION,ARG0];

    $kernel->post(
        $heap->{functionnet}->{obj}->{id},
        'com',
        {
            command =>  'HELO',
            id      =>  $session->ID
        }
    );
}

sub _loop {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    $kernel->delay_add('_loop' => 1);
}

sub _stop {
    say "_stop called";
}

1;
