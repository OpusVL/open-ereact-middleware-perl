package POE::Component::FunctionNet::Interface;

=head1 NAME

POE::Component::FunctionNet::Interface; - Abstracted interface functions

=head1 SYNOPSIS

=for comment Brief examples of using the module.

=head1 DESCRIPTION

=for comment The module's description.

=cut

# Internal perl
use v5.30.0;
use feature 'say';

# Internal perl modules (core)
use strict;
use warnings;

# Internal per modules (debug)
use Data::Dumper;

# Internal perl modules (core,recommended)
use utf8;
use open qw(:std :utf8);
use experimental qw(signatures);

# External modules
use POE qw(
    Component::FunctionNet
    Filter::Reference
    Wheel::ReadWrite
);
use Carp;
use Acme::CommandCommon;
use Data::UUID;

# Version of this software
our $VERSION = '0.001';

=head1 Methods

=cut

# Primary code block
sub new {
    my ($class,$callback_ref,$tag) = @_;

    my $self = bless {
        alias       =>  __PACKAGE__,
        session     =>  0,
        callback    =>  $callback_ref,
        buffer      =>  {
            send        =>  [],
            recv        =>  []
        },
        tag         =>  $tag
    }, $class;

    $self->{session} = POE::Session->create(
        object_states   => [
            $self => [qw(
                _start
                _loop
                _stop
                _attach
                _pong
                _timeout
                _send
                _recv
                _com
                _proc_queue
            )]
        ],
        heap    =>  { 
            state   =>  {
                UUID    =>  Data::UUID->new(),
            },
        }
    );

    my $interface_id = $self->{session}->ID; 

    $self->{engine} = POE::Component::FunctionNet->new($interface_id,'_com');

    return $self;
}

sub _start {
    my ($kernel,$heap,$session,$self) = @_[KERNEL,HEAP,SESSION,OBJECT];

    my $tag = $self->{tag};

    if ($self->{callback}) {
        say STDERR "[$tag] Callback!";
        $self->{callback}($tag);
    }
    else {
        say STDERR "[$tag] No callback!";
    }

    $kernel->yield('_loop');
}

sub _stop {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
}

sub _loop {
    my ($self,$kernel,$heap) = @_[OBJECT,KERNEL,HEAP];

    if (defined $heap->{keepalive}) {
        $kernel->yield('_timeout');
        $kernel->post($self->{engine}->ID,'_ping',time);
    }

    # Kick poe to check its send buffer
    $kernel->yield('_proc_queue');

    $kernel->delay_add('_loop' => 1);
}

sub _timeout {
    my ($self,$kernel,$heap,$time) = @_[OBJECT,KERNEL,HEAP,ARG0];

    # This has been triggered by a post from functionnet
    if ($time) {
        #$heap->{keepalive} = time;
    }

    if (
        (time - $heap->{keepalive}) > 10
    ) {
        say STDERR "Debug: Timeout after 10 seconds shutting down";
        die;
    }
}

sub _pong {
    my ($self,$kernel,$heap,$time) =  @_[OBJECT,KERNEL,HEAP,ARG0];
    $kernel->yield('_timeout',$time);
}

sub attach($self) {
    my $session_id  =   $self->{session}->ID;
    POE::Kernel->call($session_id,'_attach');
}

sub _attach {
    my ($self,$kernel,$heap) = @_[OBJECT,KERNEL,HEAP];

    $heap->{keepalive} = time;

    $kernel->call($self->{engine}->ID,'_attach');
}

sub load($self,$args) {
    my $session_id  =   $self->{session}->ID;
    my $result = POE::Kernel->post($self->{engine}->ID,'_load',$args);
}

# Requests by the client
sub offer($self,$func) {
    $self->enqueue(
        {
            command     =>  'offer',
            args        =>  $func
        },
        'send'
    );

    # Kick poe to check its send buffer
    POE::Kernel->post($self->{session}->ID,'_proc_queue');
}

# Packets from the master process
sub _com {
    my ($self,$kernel,$heap,$packet) = @_[OBJECT,KERNEL,HEAP,ARG0];

    $self->enqueue(
        $packet,
        'recv'
    );
}

sub enqueue($self,$args,$direction) {
    push @{$self->{buffer}->{$direction}},$args;
}

sub _proc_queue {
    my ($self,$kernel,$heap) = @_[OBJECT,KERNEL,HEAP];

    foreach my $direction (qw(send recv)) {
        my $size_of_buffer = scalar( @{$self->{buffer}->{$direction}} );

        if ($size_of_buffer == 0) {
            next;
        }

        my $data        =   shift @{$self->{buffer}->{$direction}};
        my $command     =   $data->{command};

        $kernel->yield("_$direction",$data)
    }
}

sub _send {
    my ($self,$kernel,$heap,$data) = @_[OBJECT,KERNEL,HEAP,ARG0];

    my $send_check  =   $kernel->post($self->{engine}->ID,'_send',$data);
    if (!$send_check)   { die "Critical - send to master failed" }
}

sub _recv {
    my ($self,$kernel,$heap,$data) = @_[OBJECT,KERNEL,HEAP,ARG0];

    $self->{callback}($data);
}

1;
