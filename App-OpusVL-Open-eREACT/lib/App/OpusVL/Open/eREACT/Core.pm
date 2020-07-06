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
use POE qw(Wheel::Run Filter::Reference Filter::Line);
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
                _add_worker
                task_stderr
                task_stdout
                task_stdin
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

    $kernel->yield('_add_worker');
    $kernel->yield('_loop');
}

sub _add_worker {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    $heap->{stash}->{filter_ref} =
        POE::Filter::Reference->new(Serializer => 'Storable');

    my $task = POE::Wheel::Run->new(
        Program         =>  ['oe','child'],
        StdinFilter     =>  $heap->{stash}->{filter_ref},
        StdoutFilter    =>  $heap->{stash}->{filter_line},
        StderrFilter    =>  $heap->{stash}->{filter_ref},
        StdoutEvent     =>  "task_stdout",
        StderrEvent     =>  "task_stderr",
        StdinEvent      =>  "task_stdin",
        CloseEvent      =>  "task_exit",
    );

    $heap->{stash}->{protocol} = 
        App::OpusVL::Open::eREACT::Protocol->new($task);

    my $childwid    =  $task->ID;
    my $childpid    =  $task->PID;

    say "Child started with pid $childpid";

    $kernel->sig_child($childpid, "got_child_signal");

    $heap->{children_by_wid}->{$childwid} = $task;
    $heap->{children_by_pid}->{$childpid} = $task;
}

sub _loop {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    $kernel->delay_add('_loop' => 1);
}

sub _stop {
    say "_stop called";
}

sub task_stderr {
    my ($heap, $stdout_line, $wheel_id) = @_[HEAP, ARG0, ARG1];

    my $stdout = $stdout_line->[0];

    my $child = $heap->{children_by_wid}->{$wheel_id};
    print "pid ", $child->PID, " STDERR: $stdout\n";
}

sub task_stdout {
    my ($heap, $stderr_line, $wheel_id) = @_[HEAP, ARG0, ARG1];

    my $child = $heap->{children_by_wid}->{$wheel_id};
    print "pid ", $child->PID, " STDOUT: $stderr_line\n";
}

sub task_stdin {
    my ($heap, $stderr_line, $wheel_id) = @_[HEAP, ARG0, ARG1];

    my $child = $heap->{children_by_wid}->{$wheel_id};
    print "pid ", $child->PID, " STDIN: $stderr_line\n";
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
