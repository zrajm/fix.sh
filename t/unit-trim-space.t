#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2016 zrajm <fix@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "dashtap/dashtap.sh"
title - <<"EOF"
Unit tests for is_alphanumeric().
EOF

init_test

################################################################################

import_function trim_space <"$TESTCMD"

while IFS=: read -r WANTED DATA; do
    case "$WANTED" in ("#"*|"") continue; esac   # skip comments + blank lines
    GOT="$(trim_space "$DATA")"; RC="$?"
    is "$RC"  0         "Should always return 0 (true)"
    is "$GOT" "$WANTED" "Should output '$WANTED' for '$DATA'"
done <<END_TESTS
###########################################################################
abc:     abc     :
abc:   abc:
abc:abc          :
abc:abc:
a b  c:   a b  c   :
###########################################################################
END_TESTS

done_testing

#[eof]
