package App::OpusVL::Open::eREACT::Command::run;

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

# External modules
use App::OpusVL::Open::eREACT -command;
use POE qw();

# Version of this software
our $VERSION = '0.001';

# Primary code block
sub abstract { 
    "Primary function"
}

sub description { 
    "Long description ... its the server for all the workers TODO"
}

sub opt_spec {
    return (
        [ "run|r",  "Run the application" ]
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    # no args allowed but options!
    $self->usage_error("No args allowed") if @$args;
}

sub execute {
    my ($self, $opt, $args) = @_;

    say 'hello';
}


=head1 AUTHOR

Paul G Webster <support@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;