#!perl

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
use POE qw(Component::FunctionNet::Interface);

use Data::Dumper;

# Version of this software
my $VERSION = '0.001';

our $handler =   \&handler;

exit do { main(); POE::Kernel->run() };

sub main {
    my $interface   =
        POE::Component::FunctionNet::Interface->new($handler,'plan.pl');

    $interface->attach;

    $interface->offer('test_func');
}

sub handler($packet) {
    warn "handler (plan.pl)";
    warn Dumper($packet);
}
