package POE::Component::FunctionNet;

=head1 NAME

POE::Component::FunctionNet - Create a network of abstract fuctions

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
    Filter::Reference
    Wheel::Run
);
use Carp;
use Acme::CommandCommon;

# Version of this software
our $VERSION = '0.001';

# Primary code block
sub new {
    my ($class,$interface_id,$interface_handler) = @_;

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
                _com
                _attach
                _ping
                _load
                _send

                task_stdout
                task_stdin
                task_exit
            )]
        ],
        heap            =>  {
            interface       =>  {
                id              =>  $interface_id,
                handler         =>  $interface_handler
            },
            filter     =>  {
                reference => POE::Filter::Reference->new(Serializer => 'Storable'),
            },
            buffer      =>  {
                send        =>  [],
                recv        =>  []
            },
            offer       =>  {

            }
        }
    );

    return $self;
}

sub ID($self) {
    return $self->{session}->ID;
}

sub _start {
    my ($kernel,$heap,$session,$self) = @_[KERNEL,HEAP,SESSION,OBJECT];

    $kernel->yield('_loop');
}

sub _com {
    warn "Function Net COM!";
}

sub _loop {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    $kernel->delay_add('_loop' => 1);
}

sub _stop {
    say "_stop called";
}

sub _ping {
    my ($kernel,$sender,$heap,$time) = @_[KERNEL,SENDER,HEAP,ARG0];
    $kernel->post($sender->ID,'_pong',$time,time);
}

sub _attach {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    $heap->{stdio}    =   POE::Wheel::ReadWrite->new(
        InputHandle     =>  \*STDIN,
        OutputHandle    =>  \*STDOUT,
        Filter          =>  POE::Filter::Reference->new(Serializer => 'Storable'),
        InputEvent      =>  "task_stdin",
    );
}

# sub _register {
#     my ($kernel,$heap) = @_[KERNEL,HEAP];

#     $heap->{stdio}->put(
#         {
#             command     =>  'register'
#         }
#     );
# }

# Start a new process via readwrite wheel
sub _load {
    my ($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];


    my $task = POE::Wheel::Run->new(
        Program         =>  $args,
        StdinFilter     =>  $heap->{filter}->{reference},
        StdoutFilter    =>  $heap->{filter}->{reference},
        StdoutEvent     =>  "task_stdout",
        StdinEvent      =>  "task_stdin",
        CloseEvent      =>  "task_exit",
    );

    # Store the plugin against its wheel id
    my $wid = $task->ID;
    $heap->{plugins}->{$wid} = $task
}

# Offer a function to the network
sub _send {
    my ($kernel,$heap,$args) = @_[KERNEL,HEAP,ARG0];

    $heap->{stdio}->put($args);
}

sub task_stdout {
    my ($kernel,$heap, $packet, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];

    my $child       =   $heap->{process};

    say STDERR join(' ','STDOUT',Dumper($packet));

    # Markwhere the request came from
    $packet->{source}   =   $wheel_id;

    # If someone has told us what they offer, send them back what we offer
    if ($packet->{command} eq 'offer') {
        my $func_offered = $packet->{args};
        push @{$heap->{offer}->{$func_offered}},$packet->{source};
        $heap->{plugins}->{$wheel_id}->put({
            command     =>      'offer',
            args        =>      [keys %{ $heap->{offer} }]
        })
    }
}

sub task_stdin {
    my ($kernel, $heap, $packet, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];

    my $child       =   $heap->{process};

    if (ref($packet) ne 'HASH') {
        say STDERR 'Unknown ingress packet! (ignored)';
        say STDERR Dumper($packet,$wheel_id);
        return;
    }

    say STDERR join(' ','STDIN',Dumper($packet));

    # If we wanted to get involved with what was going where, here would be the
    # place to do it, remember that this STDIN is on the plugin not master 
    # process!

    $kernel->post(
        $heap->{interface}->{id},
        $heap->{interface}->{handler},
        $packet
    );
}

sub task_exit {
    my ($heap,$wheel_id) = @_[HEAP,ARG0];

    my $child       =   delete $heap->{process};

    # May have been reaped by on_child_signal().
    unless (defined $child) {
        print "wid $wheel_id closed all pipes.\n";
        return;
    }

    my $pid = $child->PID;

    print "pid $pid closed all pipes.\n";
    delete $heap->{child}
}

=head1 AUTHOR

Paul G Webster <daemon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Paul G Webster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;
