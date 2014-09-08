#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
title - <<"EOF"
Attempt to rebuild target when previous target exist and is modified, and
target's metadata file has been erased. (Based on b02.)
EOF

init_test
mkdir fix src

write_file a+x -1sec fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "OUTPUT"
END_SCRIPT
write_file -1sec build/TARGET <<-"END_TARGET"
	OUTPUT2
END_TARGET

ERRMSG="ERROR: Old target 'build/TARGET' modified by user, won't overwrite
    (Erase old target before rebuild. New target kept in 'build/TARGET--fixing'.)"

timestamp TARGET        build/TARGET

file_exists     build/TARGET         "Before build: Target should exist"
file_not_exists .fix/state/TARGET    "Before build: Metadata file shouldn't exist"

"$TESTCMD" TARGET >stdout 2>stderr
is              $?                   1             "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"
file_is         build/TARGET         "OUTPUT2"     "Target"
is_unchanged    "$TARGET"                          "Target timestamp"
file_not_exists .fix/state/TARGET                  "Metadata file shouldn't exist"
file_is         build/TARGET--fixing "OUTPUT"      "Target tempfile"

done_testing

#[eof]