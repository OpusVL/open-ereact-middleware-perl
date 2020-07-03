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
use Carp;
use Acme::CommandCommon;
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

sub usage_desc {
    return "test";
}

sub validate_args($self, $opt, $args) {
    my $common = Acme::CommandCommon->new(1);

    if ($common->arrayref_length($args) != 1) {
        $self->usage_error("Requires a bind server:port using 1 argument.");
    }

    my ($bind_ip,$bind_port) = $common->exec('split_on_seperator',$args->[0]);
    my ($bind_failure) = $common->exec('test_tcp4_bind',$bind_ip,$bind_port);

    if ($bind_failure) {
        $self->usage_error("Could not bind to $bind_ip:$bind_port");
    }

    $opt->{bind}->{ip}      =   $bind_ip;
    $opt->{bind}->{port}    =   $bind_port;
}

sub execute($self, $opt, $args) {
    $self->{core} = App::OpusVL::Open::eREACT::Core->new(
        $opt->{bind}->{ip},
        $opt->{bind}->{port}
    );
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