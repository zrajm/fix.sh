#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Unit tests for relpath().
EOF

init_test

################################################################################

# Usage: VARNAME - VALUE
#
# Mock for `seteval` (used by `relpath` function). Just pass through value by
# setting VARNAME to VALUE.
seteval() { eval "$1=\$3"; }
say() { printf "%s\n" "$@"; }

import_function relpath <"$TESTCMD"

while read FILE CWD WANTED; do
    case "$FILE" in ("#"*|"") continue; esac   # skip comments + blank lines
    GOT="$(relpath "$FILE" "$CWD")"            # run test
    is "$GOT" "$WANTED" "\"$FILE\" (in \"$CWD\") should be \"$WANTED\" not \"$GOT\""
done <<END_TESTS
###########################################################################
# FILE  CWD     WANTED
###########################################################################
/       /       .
/-      /-      .
/?      /?      .
/??     /??     .
/???    /???    .
/?*     /?*     .
/*      /*      .
/**     /*      ../**
/***    /*      ../***
/*.**   /*.*    ../*.**
/*.??   /*.???  ../*.??
/[]     /[]     .
/[0-9]* /[a-z]* ../[0-9]*

/a      /a      .
/a/b/c  /a/b/c  .
/a      /       a
/a/b/c  /a/b    c
/a/b    /       a/b
/a/b/c  /a      b/c
/a/b/c  /       a/b/c

/       /a      ..
/a      /a/b    ..
/a/b    /a/b/c  ..
/a/b/c  /a/b/x  ../c
/a/c    /a/b    ../c
/b.     /a.     ../b.
/a/b/c  /x      ../a/b/c

/       /a/b    ../..
/a/c    /a/b/c  ../../c
/b/a    /a/b    ../../b/a
/a/b/c  /a/x/z  ../../b/c
/a/b/c  /x/y    ../../a/b/c

/x      /a/b/c  ../../../x
/x/y/z  /a/b/c  ../../../x/y/z
###########################################################################
END_TESTS

done_testing

#[eof]
