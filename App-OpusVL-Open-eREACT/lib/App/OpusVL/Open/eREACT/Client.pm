package App::OpusVL::Open::eREACT::Client;

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

# Internal modules (dist)
use App::OpusVL::Open::eREACT::Protocol;

# External modules
use POE qw(Filter::Reference Wheel::ReadWrite Filter::Line);
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
                task_stdin
                task_stdout
                task_exit
            )]
        ],
        heap            =>  {
            common          =>  Acme::CommandCommon->new(1),
            config          =>  {
                bind_ip         =>  $bind_ip,
                bind_port       =>  $bind_port,
            }
        }
    );

    $self->{id} = $self->{session}->ID;

    return $self;  
}

sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    $heap->{stdio} = POE::Wheel::ReadWrite->new(
        InputHandle     =>  \*STDIN,
        OutputHandle    =>  \*STDERR,
        Filter          =>  POE::Filter::Reference->new(Serializer => 'Storable'),
        InputEvent      =>  "task_stdin",
    );

    $heap->{stash}->{start_time}    =   time;
    $heap->{stash}->{latency}       =   time;

    $heap->{com}    =   App::OpusVL::Open::eREACT::Protocol->new($heap->{stdio});

    $kernel->yield('_loop');
}

sub _loop {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    my $latency = (time - $heap->{stash}->{latency});

    if ($latency > 10) {
        say STDERR "Parent<->Child Latency exceeded 10 seconds, exiting.";
        exit 1;
    }

    $heap->{com}->ping(time);

    $kernel->delay_add('_loop' => 1,time);
}

sub _stop {
}

sub task_stdout {
    my ($heap, $stderr_line, $wheel_id) = @_[HEAP, ARG0, ARG1];

    my $child = $heap->{children_by_wid}->{$wheel_id};
    print "pid ", $child->PID, " STDOUT: $stderr_line\n";
}

sub task_stdin {
    my ($input, $wheel_id) = @_[ARG0, ARG1];
    warn $input;
}

sub task_exit {
    my ($heap,$wheel_id) = @_[HEAP,ARG0];

    my $child = delete $heap->{children_by_wid}->{$wheel_id};

    # May have been reaped by on_child_signal().
    unless (defined $child) {
        print "wid $wheel_id closed all pipes.\n";
        return;
    }

    print "pid ", $child->PID, " closed all pipes.\n";
    delete $heap->{children_by_pid}->{$child->PID};
}

sub sig_child {
    my ($heap,$pid,$status) = @_[HEAP,ARG0,ARG1];

    print "pid $pid exited with status $status.\n";
    my $child = delete $heap->{children_by_pid}->{$pid};

    # May have been reaped by on_child_close().
    return unless defined $child;

    delete $heap->{children_by_wid}->{$child->ID};
}

1;
