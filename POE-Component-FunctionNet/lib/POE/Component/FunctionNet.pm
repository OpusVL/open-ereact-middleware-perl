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

# Internal perl modules (core,recommended)
use utf8;
use open qw(:std :utf8);
use experimental qw(signatures);

# External modules
use POE qw(Wheel::Run Filter::Reference);
use Carp;
use Acme::CommandCommon;

# Version of this software
our $VERSION = '0.001';

# Primary code block
sub new {
    my ($class,$opts) = @_;

    my $self = bless {
        alias   => __PACKAGE__,
        session => 0,
    }, $class;

    $self->{session} = POE::Session->create(
        object_states   => [
            $self => [qw(_start _loop _stop)]
        ],
        heap            =>  {
            common          =>  Magnum::OpusVL::CommandCommon->new(1),
            options         =>  $opts
        }
    );

    $self->{id} = $self->{session}->ID;

    return $self;
}

sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    $heap->{stash}->{filter_ref} =
        POE::Filter::Reference->new(Serializer => 'Storable');

    if ($heap->{options}->{mode} eq 'master') {
        $kernel->post($heap->{options}->{master},'com',"hello");
    }

    $kernel->yield('_loop');
}

sub _add_worker {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    my $task = POE::Wheel::Run->new(
        Program         =>  ['oe','node'],
        StdinFilter     =>  $heap->{stash}->{filter_ref},
        StdoutFilter    =>  $heap->{stash}->{filter_line},
        StderrFilter    =>  $heap->{stash}->{filter_ref},
        StdoutEvent     =>  "task_stdout",
        StderrEvent     =>  "task_stderr",
        StdinEvent      =>  "task_stdin",
        CloseEvent      =>  "task_exit",
    );

    my $workerid    =   'worker'.$heap->{stash}->{workerid}++;

    $heap->{workers}->{$workerid} = {
        task        =>  $task,
        protocol    =>  App::OpusVL::Open::eREACT::Protocol->new($task)
    };

    my $childwid    =  $task->ID;
    my $childpid    =  $task->PID;

    say "Child started with pid $childpid";

    $kernel->sig_child($childpid, "got_child_signal");

    $heap->{children_by_wid}->{$childwid} = $workerid;
    $heap->{children_by_pid}->{$childpid} = $workerid;
}

sub _loop {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    $kernel->delay_add('_loop' => 1);
}

sub _stop {
    say "_stop called";
}

sub task_stderr {
    my ($heap, $stderr_line, $wheel_id) = @_[HEAP, ARG0, ARG1];

    my $workerid    =   $heap->{children_by_wid}->{$wheel_id};
    my $child       =   $heap->{workers}->{$workerid}->{task};

    my $protocol    =   $heap->{workers}->{$workerid}->{protocol};

    my ($cmd,@args) =   $protocol->process(@{$stderr_line});

    my $output      =   join(' ','pid',$child->PID,"STDERR($cmd)",join(',',@args));

    say $output;
}

sub task_stdout {
    my ($heap, $stderr_line, $wheel_id) = @_[HEAP, ARG0, ARG1];

    my $workerid    =   $heap->{children_by_wid}->{$wheel_id};
    my $child       =   $heap->{workers}->{$workerid}->{task};

    print "pid ", $child->PID, " STDOUT: $stderr_line\n";
}

sub task_stdin {
    my ($heap, $stderr_line, $wheel_id) = @_[HEAP, ARG0, ARG1];

    my $child = $heap->{children_by_wid}->{$wheel_id}->{task};
    print "pid ", $child->PID, " STDIN: $stderr_line\n";
}

sub task_exit {
    my ($heap,$wheel_id) = @_[HEAP,ARG0];

    my $workerid    =   delete $heap->{children_by_wid}->{$wheel_id};
    my $child       =   delete $heap->{workers}->{$workerid};

    # May have been reaped by on_child_signal().
     unless (defined $child->{task}) {
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

=head1 AUTHOR

Paul G Webster <daemon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Paul G Webster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;
