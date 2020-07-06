package App::OpusVL::Open::eREACT::Protocol;

=head1 NAME

App::OpusVL::Open::eREACT::Protocol - Small protocol used between Core and Child

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
    my ($class,$parent) = @_;

    my $self = bless {
        parent => $parent
    }, $class;

    return $self;
}

sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    $kernel->yield('_loop');
}

sub ping($self,@args) {
    $self->{parent}->put(['PING',@args]);
}

1;
