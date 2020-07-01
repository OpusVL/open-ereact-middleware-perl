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

# Internal App modules
use App::OpusVL::Open::eREACT -command;
use App::OpusVL::Open::eREACT::Core;

# External modules
use Magnum::OpusVL::CommandCommon;
use POE;

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

    my $common = Magnum::OpusVL::CommandCommon->new();
    my ($bind_ip,$bind_port) = $common->extract_hostport($args->[0]);

    if (!$bind_port) {
        $self->usage_error(
            "1 Argument in the style: BIND_IP:BIND_PORT is required."
        );
    }

    my $bind_test = $args->[0] || '';

    # no args allowed but options!
    # $self->usage_error("No args allowed") if @$args;
}

sub execute {
    my ($self, $opt, $args) = @_;

    $self->{core} = App::OpusVL::Open::eREACT::Core->new($args);
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