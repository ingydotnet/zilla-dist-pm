use strict;
package Zilla::Dist;
our $VERSION = '0.0.56';

use YAML::XS;
use File::Share;
use IO::All;

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub run {
    my ($self, @args) = @_;
    @args = ('setup') unless @args;
    my $cmd = shift @args;
    my $method = "do_$cmd";
    $self->usage unless $self->can($method);
    $self->$method(@args);
}

sub do_setup {
    my ($self, @args) = @_;

    my $sharedir = $self->find_sharedir;

    my $makefile_content = io->file("$sharedir/Makefile")->all;
    io->file('Makefile')->print($makefile_content);

    my $meta_content = io->file("$sharedir/Meta")->all;
    io->file('Meta')->print($meta_content);

    print <<'...';
Zilla::Dist created files: Makefile and Meta.
...
}

sub do_sharedir {
    my ($self, @args) = @_;
    print $self->find_sharedir . "\n";
}

my $default = {
    branch => 'master',
};
sub do_meta {
    my ($self, $key) = @_;
    my $meta = YAML::XS::LoadFile('Meta');
    my $value = $meta->{$key} || $default->{$key};
    print "$value\n";
}

sub find_sharedir {
    my ($self, @args) = @_;
    my $sharedir = File::Share::dist_dir('Zilla-Dist');
    -d $sharedir or die "Can't find Zilla::Dist share dir";
    return $sharedir;
}

sub usage {
    die <<'...';

Usage:
        zild            # Make the directory be Zilla::Dist enabled;
                        # Creates new Zilla::Dist Makefile and Meta files.

Internal commands issued by the Makefile:

        zild sharedir   # Print the location of the Zilla::Dist share dir
        zild meta <key> # Print Meta value for a key

...
}

1;
