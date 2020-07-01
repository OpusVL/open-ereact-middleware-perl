package Magnum::OpusVL::CommandCommon;

=head1 NAME

Magnum::OpusVL::CommandCommon - A common set of functions 

=head1 SYNOPSIS

=for comment Brief examples of using the module.

    my $command = Magnum::OpusVL::CommandCommon->new(1);
    my $count = 
        $command->exec('count_occurences',qr/some_text/,'some_text and some_text');

=head1 DESCRIPTION

=for comment The module's description.

CommandCommon is a strictly versioned set of functions, the logic of using it 
being that any version of any function will never be changed, it may be adjusted
in a later version but all versions are strictly callable.

In the event a function is not availible in a version, the function will be 
inherited from the previous version.

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
use Module::Pluggable instantiate => 'new';

# Version of this software
our $VERSION = '0.001';

=head2 new

Create a new CommandCommon interface, takes 1 mandatory argument of version.

To use the V1 command set: ->new(1);

Likewise to use V3, ->new(3)

=cut

# Primary code block
sub new {
    my ($class,$args) = @_;

    my $self = bless {
        args    =>  $args
    }, $class;

    my @plugins = $self->plugins();
    my $plugins;

    foreach my $plugin (@plugins) {
        my $name        =   ref $plugin;
        my $version     =   $plugin->{version};
        say "Found: $name";
        foreach my $plugin (@plugins) {
            my $name        =   ref $plugin;
            my $version     =   $plugin->{version};

            foreach my $function (keys %{$plugin->{functions}}) {
                push @{$plugins->{$function}},$version;
            }
        }
    }

    use Data::Dumper;
    say Dumper($plugins);

    return $self;  
}

=head2 exec

Run a function in the CommandCommon plugin stack

=cut

sub exec {
    my ($kernel,$heap,$function,@args) = @_;
}

sub _find_plugins {
    my $self    = @_;

    my @plugins = $self->plugins();
    my $plugins;

    foreach my $plugin (@plugins) {
        my $name        =   ref $plugin;
        my $version     =   $plugin->{version};

        foreach my $function (keys %{$plugin->{functions}}) {
            say "Function: $function";
        }
    }
}


=head1 AUTHOR

Paul G Webster <daemon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Paul G Webster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;
