#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "dashtap/dashtap.sh"
title - <<"EOF"
Attempt to rebuild target after buildscript have been changed so that it
outputs something new and target's metadata file has been erased. (Based on
b02.)
EOF

init_test
mkdir .fix fix src

write_file a+x -1sec fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "OUTPUT2"
END_SCRIPT
write_file -1sec build/TARGET <<-"END_TARGET"
	OUTPUT
END_TARGET

ERRMSG="ERROR: Old target 'build/TARGET' modified by user, won't overwrite
    (Erase old target before rebuild. New target kept in 'build/TARGET--fixing'.)"

# Don't check metadata timestamp (only content is relevant).
timestamp TARGET        build/TARGET

file_exists     build/TARGET         "Before build: Target should exist"
file_not_exists .fix/state/TARGET    "Before build: Metadata file shouldn't exist"

"$TESTCMD" build/TARGET >stdout 2>stderr; RC="$?"

is              "$RC"                1             "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"
file_is         build/TARGET         "OUTPUT"      "Target"
is_unchanged    "$TARGET"                          "Target timestamp"
file_not_exists .fix/state/TARGET                  "Metadata file shouldn't exist"
file_is         build/TARGET--fixing "OUTPUT2"     "Target tempfile"

done_testing

#[eof]
