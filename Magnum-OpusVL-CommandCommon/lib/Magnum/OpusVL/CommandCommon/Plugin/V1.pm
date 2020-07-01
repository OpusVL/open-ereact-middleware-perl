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

# External modules - Core
use Carp;
use Try::Tiny;

# External modules - Net
use Socket qw(PF_INET SOCK_STREAM pack_sockaddr_in inet_aton inet_pton);
use IO::Socket qw(AF_INET AF_UNIX);
use IO::Socket::INET;

# Version of this software
our $VERSION = '0.001';

# Primary code block
sub new {
    my ($class,$args) = @_;

    my $self = bless {
        functions   =>  {
            count_occurrences   =>  \&count_occurrences,
            split_on_seperator  =>  \&split_on_seperator,
            test_tcp4_bind      =>  \&test_tcp4_bind,
            valid_ipv4          =>  \&valid_ipv4,
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
        croak "Invalid arguments passed to function";
    }

    my $count = () = $data =~ /$match_criteria/g;

    return $count;
}

=head2 split_on_seperator

Split a string into two components a head and a tail.

Accepts 1 mandatory argument and 1 optional argument:

    Arg1: The string to operate on.
    Arg2: The optional seperator, defaults to ':'.

Will return a list containing 2 items the head and tail.

=cut

sub split_on_seperator($self,$string,$seperator = ':') {
    if (!$string) {
        croak "No value passed to process.";
    }
    my ($head,$tail) = split(/$seperator/,$string,2);
    return ($head,$tail);
}

=head2 test_tcp4_bind

Attempt to bind a port on ipv4/tcp.

If you wish to check for permission to just bind anyport, you should use '0'.

Accepts 2 mandatory arguments:

    Arg1: An ip
    Arg2: A port

Returns 0 on success and 1 on error.

=cut 

sub test_tcp4_bind($self,$bind_ip,$bind_port) {
    if ($self->valid_ipv4($bind_ip)) { return 1; }

    my $error_detected = 0;

    my $server = IO::Socket->new(
        Domain      => AF_INET,
        Type        => SOCK_STREAM,
        Proto       => 'tcp',
        LocalHost   => $bind_ip,
        LocalPort   => $bind_port,
        ReusePort   => 1,
        Listen      => 5,
    ) || do { $error_detected = 1 };

    return $error_detected;
}

=head2 valid_ipv4

Check if the provided ip is a valid ipv4 address.

Accepts 1 mandatory argument of an ipv4 address.

Returns 0 if the address is valid, 1 if it is not.

=cut

sub valid_ipv4($self,$ipv4) {
    my $error_detected = 0;
    try {
        inet_pton(AF_INET, $ipv4);
    }
    catch {
        $error_detected = 1;
    };
    return $error_detected;
}

=head1 AUTHOR

Paul G Webster <daemon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Paul G Webster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
