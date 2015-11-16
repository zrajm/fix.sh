#!/usr/bin/env perl
# -*- perl -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]

use strict;
use warnings;
use 5.10.0;
use Test::More;

@ARGV = ('TESTS.txt');

##############################################################################

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

    like $state, qr/^(TODO|DONE)$/, "$ARGV:$.: Tag must be TODO or DONE";
    is $num+0, $count,              "$ARGV:$.: Test number should be $count";
    if ($state eq "DONE") {
        ok(  -e $file, "$ARGV:$.: File must exist for DONE test: $file");
    } elsif ($state eq "TODO") {
        ok(! -e $file, "$ARGV:$.: File may not exist for TODO test: $file");
    }
    $last_pre = $pre;
    $count += 1;
}

##############################################################################

done_testing;

#[eof]
