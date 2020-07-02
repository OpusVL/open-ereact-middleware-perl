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
use POE;
use Carp;
use Magnum::OpusVL::CommandCommon;

# Version of this software
our $VERSION = '0.001';

# Primary code block
sub new {
    my ($class,$bind_ip,$bind_port) = @_;

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
            config          =>  {
                bind_ip         =>  $bind_ip,
                bind_port       =>  $bind_port
            }
        }
    );

    $self->{id} = $self->{session}->ID;

    return $self;  
}


sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    $heap->{counter} = 0;
    $kernel->yield('_loop');
}

sub _loop {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    if ($heap->{counter}++ >= 10) {
        say "That's all folks.";
        $kernel->yield('shutdown');
    }
    else {
        say "tick";
        $kernel->delay_add('_loop' => 1);
    }
}

sub _stop {
    say "_stop called";
}


=head1 AUTHOR

Paul G Webster <daemon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Paul G Webster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;
