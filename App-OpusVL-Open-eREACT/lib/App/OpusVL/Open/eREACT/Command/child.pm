package App::OpusVL::Open::eREACT::Command::node;

=head1 NAME

App::OpusVL::Open::eREACT::Command::run - Module abstract placeholder text

=head1 SYNOPSIS

=for comment Brief examples of using the module.

=head1 DESCRIPTION

=for comment The module's description.

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

# Internal App modules
use App::OpusVL::Open::eREACT -command;
use App::OpusVL::Open::eREACT::Node;

# External modules
use Carp;
use Acme::CommandCommon;
use POE;

# Version of this software
our $VERSION = '0.001';

# Primary code block
sub abstract { 
    "Create a child process for handling incoming connections"
}

sub description { 
    "Long description"
}

sub opt_spec {
    return (
        # Do not return anything this is a hidden call
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    # no args allowed but options!
    $self->usage_error("No args allowed") if @$args;
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $child = App::OpusVL::Open::eREACT::Node->new();
    POE::Kernel->run();
}

=head1 AUTHOR

Paul G Webster <support@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;