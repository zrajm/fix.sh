#!/usr/bin/env perl
# -*- perl -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]

use strict;
use warnings;
use 5.10.0;
use Test::More;

@ARGV = ('TESTS.txt');
my %file = map { ($_ => 1) } glob("t/*.t");    # list of test files

my ($last_pre, $count) = ("", -1);
LINE: while (<>) {
    chomp;
    my ($state, $pre, $num, $str)
        = /^[*][*] \s+ (\w+) \s+ ([a-z]) ([0-9#]{2}) [.]\s+ (.*)/x
        or next LINE;
    $count = 1 if $pre ne $last_pre;           # reset count when prefix changes
    foreach ($str) {                           # process string
        tr/A-Z/a-z/;
        s/[-'()]//g;
        s/[^a-z0-9+]+/-/g;
        s/^-+//;
        s/-+$//;
    }

    my $file = sprintf "t/%s%02d-%s.t", $pre, $num, $str;

    local $SIG{__WARN__} = sub {
        chomp(my $msg = shift);
        warn "$msg (file $ARGV, line $.)\n";
    };

    my $bad = "";
    like($state, qr/^(TODO|DONE)$/, "Should have TODO or DONE tag") or $bad = 1;
    is($num+0, $count,              "Test number should be $count") or $bad = 1;
    if ($state eq "DONE") {
        ok(delete $file{$file}, "DONE line, file should exist: $file") or $bad = 1;
    } elsif ($state eq "TODO") {
        ok(!$file{$file},       "TODO line, file should NOT exist: $file") or $bad = 1;
    }
    $bad and diag("Test failed in line:\n  '$_'\n  (file '$ARGV', line $.)");
    $last_pre = $pre;
    $count += 1;
}

ok(!%file, "All test files should be described in 'TESTS.txt'") or
    diag "The following files do not have an entry in '$ARGV':\n",
    map { "  * $_\n" } sort keys %file;

done_testing;

#[eof]
