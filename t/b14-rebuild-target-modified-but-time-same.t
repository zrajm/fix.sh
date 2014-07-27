#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
title - <<"EOF"
Attempt to rebuild target when previous target exist and is modified, but its
timestamp and size is the same as last time. (Based on b02.)
EOF

init_test
mkdir  fix src
cpdir .fix build

write_file a+x -1sec fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "OUTPUT"
END_SCRIPT

# Replace 'build/TARGET' but keep its old timestamp and filesize.
timestamp TARGET build/TARGET
write_file build/TARGET <<-"END_TARGET"
	XXXXXX
END_TARGET
reset_timestamp "$TARGET"

ERRMSG="ERROR: Old target 'build/TARGET' modified by user, won't overwrite
    (Erase old target before rebuild. New target kept in 'build/TARGET--fixing'.)"

timestamp TARGET        build/TARGET
timestamp METADATA .fix/state/TARGET

file_exists     build/TARGET         "Before build: Target should exist"
file_exists     .fix/state/TARGET    "Before build: Metadata file should exist"

"$TESTCMD" TARGET >stdout 2>stderr
is              $?                   1             "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"
file_is         build/TARGET         "XXXXXX"      "Target"
is_unchanged    "$TARGET"                          "Target timestamp"
file_exists     .fix/state/TARGET                  "Metadata file should exist"
is_unchanged    "$METADATA"                        "Metadata timestamp"
file_is         build/TARGET--fixing "OUTPUT"      "Target tempfile"

done_testing

#[eof]
