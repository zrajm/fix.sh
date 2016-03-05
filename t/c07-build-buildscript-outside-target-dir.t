#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2016 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Test that specifying a target with a path outside the $FIX_TARGET_DIR results
in an error message, and that it suggests a new path.
EOF

init_test
mkdir .fix fix src

write_file a+x fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "NEVER RUN"
END_SCRIPT

file_not_exists build/TARGET         "Before build: Target shouldn't exist"
file_not_exists .fix/state/TARGET    "Before build: Metadata file shouldn't exist"

"$TESTCMD" TARGET >stdout 2>stderr; RC="$?"

STDOUT="$NADA"
STDERR="ERROR: Your target 'TARGET' must be inside the target dir ('build/')
    (Perhaps you meant to say 'build/TARGET'?)"

is              "$RC"                16            "Exit status"
file_is         stdout               "$STDOUT"     "Standard output"
file_is         stderr               "$STDERR"     "Standard error"

done_testing

#[eof]
