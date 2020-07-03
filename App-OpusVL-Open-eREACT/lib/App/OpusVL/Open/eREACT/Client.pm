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

    $heap->{com} = POE::Wheel::ReadWrite->new(
        InputHandle     =>  *STDIN,
        OutputHandle    =>  *STDERR,
        Filter          =>  POE::Filter::Reference->new(Serializer => 'Storable'),
        InputEvent      =>  "task_stdin",
    );


    $kernel->yield('_loop');
}

sub _loop {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    $heap->{com}->put(['TEST']);

    $kernel->delay_add('_loop' => 1);
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
