#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "dashtap/dashtap.sh"
title - <<"EOF"
Unit tests for is_alphanumeric().
EOF

init_test

################################################################################

import_function is_alphanumeric <"$TESTCMD"

while read WANTED VARNAME; do
    case "$WANTED" in ("#"*|"") continue; esac   # skip comments + blank lines
    is_alphanumeric "$VARNAME"; RC="$?"
    if [ "$WANTED" = 0 ]; then SHOULD=true; else SHOULD=false; fi
    is "$RC" "$WANTED" "is_alphanumeric() should return $WANTED ($SHOULD) for '$VARNAME'"
done <<END_TESTS
###########################################################################
# VARNAME                             OKAY?
###########################################################################
0 abc123_
1 abc123-
1 123abc_
0 abcdefghijklmnopqrstuvwxyz
0 ABCDEFGHIJKLMNOPQRSTUVWXYZ
0 _0123456789
1
1 -
###########################################################################
END_TESTS

done_testing

#[eof]
