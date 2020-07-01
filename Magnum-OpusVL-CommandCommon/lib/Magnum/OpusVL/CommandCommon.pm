package Magnum::OpusVL::CommandCommon;

=head1 NAME

Magnum::OpusVL::CommandCommon - A common set of functions 

=head1 SYNOPSIS

=for comment Brief examples of using the module.

    my $command = Magnum::OpusVL::CommandCommon->new(1);
    my $count = $command->exec(
        'count_occurences',
        qr/some_text/,
        'some_text and some_text'
    );
    say "Count: $count"; # 2

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
use Carp;
use Data::Dumper;

# Version of this software
our $VERSION = '0.001';

=head2 new

Create a new CommandCommon interface, takes 1 mandatory argument of version.

To use the V1 command set: ->new(1);

Likewise to use V3, ->new(3)

=cut

# Primary code block
sub new {
    my ($class,$target_version) = @_;

    if (!$target_version || $target_version !~ m/^\d+$/) {
        croak '->new() requires one argument: version, e.g.: ->new(2)';
    }

    my $self = bless {}, $class;

    # A place to store a copy of the plugins for sorting
    my $plugin_sort;

    # Instanciate and store the plugins.
    foreach my $plugin ($self->plugins()) {
        my $plugin_name             =   ref $plugin;

        # Store the plugin in $self
        $self->{plugins}->{$plugin_name}       =   $plugin;

        # Find the plugin version
        my $plugin_version          =
            $self->{plugins}->{$plugin_name}->{version};

        # Do not process plugins we do not require
        if ($plugin_version > $target_version) { next; }

        # Look through availible functions and find the closest to our target
        # version
        foreach my $function (
            keys %{ $self->{plugins}->{$plugin_name}->{functions} }
        ) {
            if (
                !$plugin_sort->{$function} 
                || 
                $plugin_sort->{$function}->{version} < $target_version
            )
            {
                $plugin_sort->{$function}->{version}    =   $plugin_version;
                $plugin_sort->{$function}->{parent}     =   $plugin_name;
            }
        }
    }

    # Loop through the pluginsort and build the interface
    foreach my $function_name (keys %{$plugin_sort}) {
        my $function                    =   $plugin_sort->{$function_name};
        my $plugin_name                 =   $function->{parent};

        $self->{interface}->{$function_name} =
            sub { $self->{plugins}->{$plugin_name}->$function_name(@_) };
    }

    return $self;  
}

=head2 exec

Run a function in the CommandCommon plugin stack

=cut

sub exec {
    my ($self,$function,@args) = @_;

    return $self->{interface}->{$function}(@args);
}

sub show_plugins {
    my $self    = @_;

    my @plugins = $self->plugins();
    my $plugins;

    foreach my $plugin (@plugins) {
        my $name        =   ref $plugin;
        my $version     =   $plugin->{version};

        foreach my $function (keys %{$plugin->{functions}}) {
            $plugins->{$name}->{$function} = sub{$plugin->$function};
        }
    }

    return $plugins;
}


=head1 AUTHOR

Paul G Webster <daemon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Paul G Webster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;
