package Magnum::OpusVL::CommandCommon::Plugin::V2;

=head1 NAME

Magnum::OpusVL::CommandCommon::V2 - Version 2 common commands

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
use Carp;

# Version of this software
our $VERSION = '0.001';

# Primary code block
sub new {
    my ($class,$args) = @_;

    my $self = bless {
        functions   =>  {
        },
        version     =>  2,
    }, $class;

    return $self;  
}

=head1 AUTHOR

Paul G Webster <daemon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Paul G Webster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;
