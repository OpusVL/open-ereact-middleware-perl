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
                task_stderr
                task_stdout
                task_exit
                sig_child
            )]
        ],
        heap            =>  {
            common          =>  Acme::CommandCommon->new(1),
            config          =>  {
                bind_ip         =>  $bind_ip,
                bind_port       =>  $bind_port,
                tasks           =>  {
                    
                }
            }
        }
    );

    $self->{id} = $self->{session}->ID;

    return $self;  
}


sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    $kernel->yield('_loop');
}

sub _add_worker {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    my $task = POE::Wheel::Run->new(
        Program      => ['oe','child'],
        StdoutFilter => POE::Filter::Reference->new(),
        StdoutEvent  => "task_result",
        StderrEvent  => "task_debug",
        CloseEvent   => "task_done",
    );

    my $childwid    =  $task->ID;
    my $childpid    =  $task->PID;

    $kernel->sig_child($childpid, "got_child_signal");

    $heap->{children_by_wid}->{$childwid} = $task;
    $heap->{children_by_pid}->{$childpid} = $task;

    my $filter = POE::Filter::Reference->new();
}

sub _loop {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    $kernel->delay_add('_loop' => 1);
}

sub _stop {
    say "_stop called";
}

sub task_stderr {
    my ($stdout_line, $wheel_id) = @_[ARG0, ARG1];

    my $child = $_[HEAP]{children_by_wid}{$wheel_id};
    print "pid ", $child->PID, " STDERR: $stdout_line\n";
}

sub task_stdout {
    my ($stderr_line, $wheel_id) = @_[ARG0, ARG1];

    my $child = $_[HEAP]{children_by_wid}{$wheel_id};
    print "pid ", $child->PID, " STDERR: $stderr_line\n";
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
