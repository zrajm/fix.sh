#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "dashtap/dashtap.sh"
title - <<"EOF"
Attempt to rebuild target when previous target exist and is modified, but its
timestamp and size is the same as last time. (Based on b02.)
EOF

init_test
mkdir  fix src
cpdir .fix build

write_file a+x -1sec fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "OUTPUT"
END_SCRIPT

# Replace 'build/TARGET' but keep its old timestamp and filesize.
timestamp TARGET build/TARGET
write_file build/TARGET <<-"END_TARGET"
	6BYTES
END_TARGET
reset_timestamp "$TARGET"

ERRMSG="ERROR: Old target 'build/TARGET' modified by user, won't overwrite
    (Erase old target before rebuild. New target kept in 'build/TARGET--fixing'.)"

# Don't check metadata timestamp (only content is relevant).
timestamp TARGET        build/TARGET

file_exists     build/TARGET         "Before build: Target should exist"
file_exists     .fix/state/TARGET    "Before build: Metadata file should exist"

"$TESTCMD" build/TARGET >stdout 2>stderr; RC="$?"

DBDATA="$(
    set -e
    echo OUTPUT     | mkmetadata TARGET TARGET
    <<-"END_SCRIPT"   mkmetadata SCRIPT TARGET.fix # old buildscript
	#!/bin/sh
	set -eu
	echo "OUTPUT"
	END_SCRIPT
)" || fail "Failed to calculate metadata"

is              "$RC"                1             "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"
file_is         build/TARGET         "6BYTES"      "Target"
is_unchanged    "$TARGET"                          "Target timestamp"
file_is         .fix/state/TARGET    "$DBDATA"     "Target metadata"
first_dep_is    .fix/state/TARGET    "TARGET"      "Target metadata target first"
file_not_exists .fix/state/TARGET--fixing          "Target metadata tempfile shouldn't exist"
file_is         build/TARGET--fixing "OUTPUT"      "Target tempfile"

done_testing

#[eof]
