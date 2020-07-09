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
use POE qw(Wheel::Run Session Filter::Reference Wheel::ReadWrite Component::FunctionNet::Protocol);
use Carp;
use Acme::CommandCommon;

# Version of this software
our $VERSION = '0.001';

# Primary code block
sub new {
    my ($class,$runmode) = @_;

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
                _load
                _start_as_master
                _start_as_provider
                com
                send
            )]
        ],
        heap            =>  {
            common          =>  Acme::CommandCommon->new(1),
            runmode         =>  $runmode,
            filter          =>  {
                line            =>  POE::Filter::Line->new(Literal => "\n"),
                reference       =>  POE::Filter::Reference->new(Serializer => 'Storable')
            },
            plugins         =>  {
                state           =>  {
                    id              =>  0
                }
            }
        }
    );

    $self->{id} = $self->{session}->ID;

    return $self;
}

sub _start {
    my ($kernel,$heap,$session) = @_[KERNEL,HEAP,SESSION];

    my $mode = $heap->{runmode};

    if (!$mode) {
        die "No runmode passed";
    }

    if      ($mode eq 'master')     {
        $kernel->call($session->ID,'_start_as_master');
    }
    elsif   ($mode eq 'provider')   {
        $kernel->call($session->ID,'_start_as_provider');
    }
    else                            {
        die "No idea what mode = $mode means";
    }

    $kernel->yield('_loop');
}

sub _start_as_master {
    my ($kernel,$heap,$session,$self) = @_[KERNEL,HEAP,SESSION,OBJECT];

    # What should happen here as with _start_as_provider is a POE::Session for 
    # dealing with this interface should occur
}

sub _start_as_provider {
    my ($kernel,$heap,$session,$self) = @_[KERNEL,HEAP,SESSION,OBJECT];

    my $interface = POE::Session->create(
          inline_states => {
            _start => sub { 
                $_[KERNEL]->yield("start_process");
            },
            next   => sub {
                $_[KERNEL]->delay(next => 1);
            },
            start_process   =>  sub {
                my ($kernel,$heap) = @_[KERNEL, HEAP];

                my $wheel = POE::Wheel::ReadWrite->new(
                    InputHandle     =>  \*STDIN,
                    OutputHandle    =>  \*STDERR,
                    Filter          =>  POE::Filter::Reference->new(Serializer => 'Storable'),
                    InputEvent      =>  "task_stdin",
                );

                $heap->{process}    =   $wheel;

                my $command = {
                    command =>  'HELO'
                };
                $heap->{process}->put($command);

                $kernel->yield("next");
            },
            task_stdin       =>  sub {
                my ($heap, $stderr_line, $wheel_id) = @_[HEAP, ARG0, ARG1];

                my $child       =   $heap->{process};
                my $command = {
                    command =>  'GOTCHA!',
                    details =>  $stderr_line
                };
                $heap->{process}->put($command);
            },
            send                => sub {
                my ($kernel,$heap,$data) = @_[KERNEL,HEAP,ARG0];
                $heap->{process}->put($data);
            }
        },
    );

    $self->{interface} = $interface;
}

sub com {
    my ($kernel,$heap,$sessian,$sender,$data) = @_[KERNEL,HEAP,SESSION,SENDER,ARG0];

    my $command = $data->{command};

    if      ($command eq 'HELO') {
        if (!$heap->{admin}) {
            my $admin_id = $sender->ID;
            my $admin_handler = $data->{handler};

            $heap->{admin}->{id} = $admin_id;
            $heap->{admin}->{handler} = $admin_handler;

            say "Admin registered as: $admin_id,$admin_handler";

            my $greeting = {
                command =>  'HELO'
            };
            $kernel->post($admin_id,$admin_handler,$greeting);
        }
    }
    elsif   ($command eq 'LOAD') {
        # Load a worker and a module
        my @args = @{$data->{args}};
        $kernel->yield('_load',@args);
    }
}

sub _load {
    my ($parent_kernel,$parent_heap,@args) = @_[KERNEL,HEAP,ARG0 .. $#_];

    say STDERR "Loading: ".join(',',@args);

    my $internal_id = $parent_heap->{plugins}->{state}->{id}++;

    my $session = POE::Session->create(
          inline_states => {
            _start => sub { 
                $_[KERNEL]->yield("next");
                $_[KERNEL]->yield('start_process');
            },
            next   => sub {
                $_[KERNEL]->delay(next => 1);
            },
            start_process   =>  sub {
                my ($kernel,$heap) = @_[KERNEL, HEAP];

                $heap->{filter} = POE::Filter::Reference->new(Serializer => 'Storable');

                my $task = POE::Wheel::Run->new(
                    Program         =>  [@args],
                    StdinFilter     =>  $heap->{filter},
                    StdoutFilter    =>  POE::Filter::Line->new(Literal => "\n"),
                    StderrFilter    =>  $heap->{filter},
                    StdoutEvent     =>  "task_stdout",
                    StderrEvent     =>  "task_stderr",
                    StdinEvent      =>  "task_stdin",
                    CloseEvent      =>  "task_exit",
                );

                $heap->{process}    =   $task;

                my $childpid        =   $task->PID;

                say "Child started with pid $childpid";

                $kernel->sig_child($childpid, "task_exit");
            },
            task_stdout     =>  sub {
                my ($heap, $stdout_line, $wheel_id) = @_[HEAP, ARG0, ARG1];

                my $child       =   $heap->{process};

                say "pid ", $child->PID, " STDOUT: ",Dumper($stdout_line);
            },
            task_stderr     =>  sub {
                my ($heap, $stderr_line, $wheel_id) = @_[HEAP, ARG0, ARG1];

                my $child       =   $heap->{process};
                my $command     =   $stderr_line->{command};

                if ($command eq 'register') {
                    $child->put({command=>'boop'});
                }

                say join(' ','STDERR',Dumper($stderr_line));
            },
            task_stdin      =>  sub {
                my ($heap, $stderr_line, $wheel_id) = @_[HEAP, ARG0, ARG1];

                my $child       =   $heap->{process};

                #print "pid ", $child->PID, " STDIN: $stderr_line\n";
            },
            task_exit       =>  sub {
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
        },
    );

    $parent_heap->{plugins}->{sessions}->{$internal_id} = $session;
}

sub _loop {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    $kernel->delay_add('_loop' => 1);
}

sub _stop {
    say "_stop called";
}



=head2 Object methods (for plugins)

=head3 register

Register what functions the plugin offers

=cut

sub register($self,$functions) {
    POE::Kernel->post(
        $self->{interface}->ID,
        'send',
        { 
            command=>'register', 
            args=>$functions 
        }
    );
}

sub _send($target,$data) {
    return
        POE::Kernel->post($target,'relay',$data);
}

sub send {
    die "GOT MASTER LEVEL SEND";
}


=head1 AUTHOR

Paul G Webster <daemon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Paul G Webster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;
