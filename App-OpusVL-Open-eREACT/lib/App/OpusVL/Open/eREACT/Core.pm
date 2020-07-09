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
use POE qw(Wheel::Run Component::FunctionNet);
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
                _send
                com
            )]
        ],
        heap            =>  {
            common          =>  Acme::CommandCommon->new(1),
            config          =>  {
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

    $heap->{functionnet}->{obj} = 
        POE::Component::FunctionNet->new('master');

    # Could use this to register as an exterior log store
    $kernel->yield(
        '_send',
        {
            command =>  'HELO',
            id      =>  $session->ID,
            handler =>  'com'
        }
    );

    # Start the 'plan' controller
    $kernel->yield('_loop');
}

sub com {
    my ($kernel,$heap,$session,$sender,$data) = 
        @_[KERNEL,HEAP,SESSION,SENDER,ARG0];

    use Data::Dumper;
    say Dumper($data);

    if ($data->{command} eq 'HELO') {
        $kernel->yield(
            '_send',
            {
                command =>  'LOAD',
                args    =>  [
                    'perl',
                    '/home/paul.webster/Work/Project-DigiMiddleware/open-ereact-middleware-perl/plugins/plan.pl'
                ]
            }
        );
    }
}

sub _send {
    my ($kernel,$heap,$session,$packet) = @_[KERNEL,HEAP,SESSION,ARG0];

    $kernel->post(
        $heap->{functionnet}->{obj}->{id},
        'com',
        $packet
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
