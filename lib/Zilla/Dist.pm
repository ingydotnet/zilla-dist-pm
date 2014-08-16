use strict;
package Zilla::Dist;
our $VERSION = '0.0.135';

use YAML::XS;
use File::Share;
use IO::All;
use version;

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
    $self->{meta} = -f 'Meta'
      ? YAML::XS::LoadFile('Meta')
      : {};
    $self->$method(@args);
}

sub error {
    die "Error: $_[0]\n";
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
    my $keys = [ split '/', $key ];
    my $meta = $self->{meta};
    my $value = $meta;
    for my $k (@$keys) {
        return unless ref($value) eq 'HASH';
        $value = $value->{$k} || $default->{$k};
        last unless defined $value;
    }
    if (defined $value) {
        if (not ref $value) {
            print "$value\n";
        }
        elsif (ref($value) eq 'ARRAY') {
            print "$_\n" for @$value;
        }
        elsif (ref($value) eq 'HASH') {
            for my $kk (sort keys %$value) {
                print "$kk\n" unless $kk =~ /^(?:perl)$/;
            }
        }
        else {
            print "$value\n";
        }
    }
}

sub do_changes {
    my ($self, $key, $value) = @_;
    return if $self->{meta}{'=cpan'}{no_changes_yaml};
    my @changes = YAML::XS::LoadFile('Changes');
    $self->validate_changes(\@changes);
    return unless @changes;
    if ($value) {
        chomp $value;
        die unless length $value;
        my $text = io->file('Changes')->all or die;
        my $line = sprintf "%-8s %s", "$key:", $value;
        $text =~ s/^$key:.*/$line/m or die;
        io->file('Changes')->print($text);
    }
    else {
        $value = $changes[0]{$key} or return;
        print "$value\n";
    }
}

sub validate_changes {
    my ($self, $changes) = @_;
    return if $self->{meta}{'=cpan'}{no_changes_yaml};

    scalar(@$changes) or error "Changes file is empty";

    for (my $i = 1; $i <= @$changes; $i++) {
        my $entry = $changes->[$i - 1];
        ref($entry) eq 'HASH'
            or error "Changes entry #$i is not a hash";
        my @keys = keys %$entry;
        @keys == 3
            or error "Changes entry #$i doesn't have 3 keys";
        for my $key (qw(version date changes)) {
            error "Changes entry #$i is missing field '$key'"
                unless exists $entry->{$key};
            error "Changes entry #$i has undefined field '$key'"
                unless defined $entry->{$key} or $key eq 'date';
            if (defined $entry->{$key}) {
                if ($key eq 'changes') {
                    error "Changes entry #$i field '$key' should be an array"
                        unless ref($entry->{$key}) eq 'ARRAY';
                    my $change_list = $entry->{changes};
                    for my $change_entry (@$change_list) {
                        error "Changes entry #$i has non-scalar 'changes' entry"
                            if ref $change_entry;
                    }
                }
                else {
                    error "Changes entry #$i field '$key' should be a scalar"
                        if ref($entry->{$key});
                }
            }
        }
    }
    if (@$changes >= 2) {
        my $changes1 = join '%^&*', @{$changes->[0]{changes}};
        my $changes2 = join '%^&*', @{$changes->[1]{changes}};
        error "2 most recent Changes messages cannot be the same!"
            if $changes1 eq $changes2;
        my $v0 = $changes->[0]{version};
        my $v1 = $changes->[1]{version};
        error "latest Changes version ($v0) is not greater than previous ($v1)"
            unless version->parse($v0) > version->parse($v1);
    }
}

sub find_sharedir {
    my ($self, @args) = @_;
    my $sharedir = File::Share::dist_dir('Zilla-Dist');
    -d $sharedir or die "Can't find Zilla::Dist share dir";
    return $sharedir;
}

sub do_webhooks {
    my ($self) = @_;
    return unless $ENV{PERL_ZILLA_DIST_GIT_HUB_WEBHOOKS};
    return unless -d '.git';
    my $path = '.git/zilla-dist/webhooks';
    my $travis = io->file("$path/travis");
    my $irc = io->file("$path/irc");
    for my $hook (qw(travis irc)) {
        my $file = io->file("$path/$hook");
        if ($file->exists) {
            my $hook_version = $file->chomp->getline;
            my $api_version = '0.0.95';
            next if
                version->parse($hook_version) >=
                version->parse($api_version);
        }
        my $method = "webhook_command_$hook";
        my $command = $self->$method or next;
        print "Running: '$command'\n";
        system($command) == 0
            or die "Error: command failed '$command': $!";
        io->file("$path/$hook")->assert->print($VERSION);
    }
}

sub webhook_command_travis {
    my ($self) = @_;
    return unless $self->{meta}{'=travis'};
    return "git hub travis-enable";
}

sub webhook_command_irc {
    my ($self) = @_;
    my $irc;
    return unless $irc = $self->{meta}{devel}{irc};
    return unless $irc =~ /^(\w\S*)#(\w\S*)$/;
    return "git hub irc-enable $2 $1";
}

sub do_years {
    my ($self, $key, $value) = @_;
    my %hash = eval {
        map {($_ => 1)} grep {$_} map {
            $_->{date} =~ /(\d{4})/;
            $1;
        } (YAML::XS::LoadFile('Changes'));
    };
    return if $@;
    print join(' ', sort keys %hash) . "\n";
}

sub usage {
    die <<'...';

Usage:
        zild            # Make the directory be Zilla::Dist enabled;
                        # Creates new Zilla::Dist Makefile and Meta files.

Internal commands issued by the Makefile:

        zild sharedir   # Print the location of the Zilla::Dist share dir
        zild meta <key> # Print Meta value for a key
        zild changes <key> [<value>]

...
}

1;
