# This test does a basic `use` check on all the code.
use Test::More;

use File::Find;

sub test {
    -f and /\.pm$/ or return;
    s{^lib[/\\]}{};
    s{\.pm$}{};
    s{[/\\]}{::}g;
    if (/^(?:
        Alt:: |
        Devel::Local\b |
        Sex$
    )/x) {
        ok eval("require $_; 1"), "require $_; # OK";
    }
    else {
        use_ok $_;
    }
}

find {
    wanted => \&test,
    no_chdir => 1,
}, 'lib';

done_testing;
