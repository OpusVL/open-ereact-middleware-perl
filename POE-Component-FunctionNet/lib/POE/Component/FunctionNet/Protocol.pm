package POE::Component::FunctionNet::Protocol;

=head1 NAME

POE::Component::FunctionNet::Protocol - Small baseline communication module

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

sub ping($self,@args) {
    return ['PING',@args];
}

sub helo($self,@args) {
    return ['HELO',@args];
}

sub process($self,@args) {
    
}

1;
