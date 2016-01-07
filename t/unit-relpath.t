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

# Usage: get_func NAME... <FILE
#
# Extract one or more shell function(s) with specified NAME(s). Each function
# must start with the unindented function name followed by '()' and end in a
# line which starts with an unindented '}'.
get_func() {
    local FUNC="" FOUND="" IFS="" LINE=""
    while read -r LINE; do
        for FUNC in "$@"; do
            case "$LINE" in
                "$FUNC()"*) FOUND="yes"
            esac
        done
        if [ "$FOUND" ]; then
            printf "%s\n" "$LINE"
            case "$LINE" in
                '}'*) FOUND=""
            esac
        fi
    done
}

################################################################################

# Usage: VARNAME - VALUE
#
# Mock for `seteval` (used by `relpath` function). Just pass through value by
# setting VARNAME to VALUE.
seteval() { eval "$1=\$3"; }
say() { printf "%s\n" "$@"; }

# Get `relpath` function from Fix.
eval "$(get_func relpath <"$TESTCMD")"

while read FILE CWD WANTED; do
    case "$FILE" in ("#"*|"") continue; esac   # skip comments + blank lines
    GOT="$(relpath "$FILE" "$CWD")"            # run test
    is "$GOT" "$WANTED" "'$FILE' (in '$CWD') should be '$WANTED'"
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
/a      /       ./a
/a/b/c  /a/b    ./c
/a/b    /       ./a/b
/a/b/c  /a      ./b/c
/a/b/c  /       ./a/b/c

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
