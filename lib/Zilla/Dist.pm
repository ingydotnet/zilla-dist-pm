use strict;
package Zilla::Dist;

use File::Share;
use IO::All;

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub run {
    my ($self, @args) = @_;
    $self->usage unless @args == 1;
    my $cmd = shift @args;
    my $method = "do_$cmd";
    $self->usage unless $self->can($method);
    $self->$method(@args);
}

sub do_makefile {
    my ($self, @args) = @_;

    my $makefile_content = io->file($self->find_makefile)->all;
    io->file('Makefile')->print($makefile_content);

    print <<'...';
Created Zilla::Dist Makefile.

Run: `make upgrade`.
...
}

sub do_sharedir {
    my ($self, @args) = @_;
    print $self->find_sharedir . "\n";
}

sub find_sharedir {
    my ($self, @args) = @_;
    return File::Share::dist_dir('Zilla-Dist');
}

sub find_makefile {
    my ($self, @args) = @_;
    my $makefile = $self->do_sharedir . '/Makefile';
    -e $makefile or die "Can't find Zilla::Dist Makefile";
    return $makefile;
}

sub usage {
    die <<'...';
Usage:

    zild makefile       # Create a new Zilla::Dist Makefile
    zild sharedir       # Print the location of the Zilla::Dist share dir
...
}

1;
