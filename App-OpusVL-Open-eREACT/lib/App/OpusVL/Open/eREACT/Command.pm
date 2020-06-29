package App::OpusVL::Open::eREACT::Command;
use App::Cmd::Setup -command;

=head1 NAME

App::OpusVL::Open::eREACT::Command - Global options for App::Cmd


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
use App::Cmd::Setup -app;

# Version of this software
our $VERSION = '0.001';

# Primary code block
sub opt_spec {
    my ( $class, $app ) = @_;
    return (
        [ 'help' => "this usage screen" ],
        $class->options($app),
    )
}
 
sub validate_args {
    my ( $self, $opt, $args ) = @_;
    if ( $opt->{help} ) {
        my ($command) = $self->command_names;
        $self->app->execute_command(
            $self->app->prepare_command("help", $command)
        );
        exit;
    }
    $self->validate( $opt, $args );
}