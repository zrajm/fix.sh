#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2016 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Test that --script-dir with an directory name argument that starts with minus
aborts Fix with the correct error message.
EOF

init_test

"$TESTCMD" build/ZERO >stdout 2>stderr --script-dir --thingy; RC="$?"

STDOUT="$NADA"
STDERR="ERROR: Invalid argument '--thingy' for '--script-dir'
    (Use './--thingy' if your directory name really starts with '-'.)"

is              "$RC"              15            "Exit status"
file_not_exists fix                              "Default script dir shouldn't exist"
file_is         stdout             "$STDOUT"     "Standard output"
file_is         stderr             "$STDERR"     "Standard error"

done_testing

#[eof]
