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

sub do_setup {
    my ($self, @args) = @_;

    my $makefile_content = io->file($self->find_makefile)->all;
    io->file('Makefile')->print($makefile_content);

    print <<'...';
Created Zilla::Dist Makefile.

Run: `make upgrade`.
...
}

sub do_env {
    my ($self, @args) = @_;
    my $makefile_name = $self->find_makefile;
    print <<"..."
PERL_ZILLA_DIST_MAKEFILE=$makefile_name
...
}

sub find_makefile {
    my $makefile = File::Share::dist_dir('Zilla-Dist') . '/Makefile';
    -e $makefile or die "Can't find Zilla::Dist Makefile";
    return $makefile;
}

1;
