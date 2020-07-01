package Magnum::OpusVL::CommandCommon::Plugin::V1;

=head1 NAME

Magnum::OpusVL::CommandCommon::V1 - Version 1 common commands

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

# Version of this software
our $VERSION = '0.001';

# Primary code block
sub new {
    my ($class,$args) = @_;

    my $self = bless {
        functions   =>  {
            count_occurrences   =>  \&count_occurrences,
            extract_hostport    =>  \&extract_hostport,
        },
        version     =>  1,
    }, $class;

    return $self;  
}

=head2 count_occurrences

Count the occurences of a regex or string within a string, takes two arguments:

    arg1: The match criteria as a qr// or string
    arg2: The data to match against

Will return the number of matches of arg1 in arg2.

=cut

sub count_occurrences($self,$match_criteria,$data) {
    if (!$match_criteria || !$data)  {
        die "Invalid arguments passed to function";
    }

    my $count = () = $data =~ /$match_criteria/g;

    return $count;
}

=head2 extract_hostport

Extract the host/ip and port from a single word string, for example: 1.1.1.1:53

Accepts 1 mandatory argument and 1 optional argument:

    Arg1: The hostport set.
    Arg2: The optional seperator, defaults to ':'.

Will return a list of host and port.

=cut

sub extract_hostport($self,$hostport,$seperator = ':') {
    my ($host,$port) = split(/$seperator/,$hostport,2);
    return ($host,$port);
}

=head1 AUTHOR

Paul G Webster <daemon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Paul G Webster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
