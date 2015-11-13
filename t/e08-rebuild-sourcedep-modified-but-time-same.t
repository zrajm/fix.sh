#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
title - <<"EOF"
Rebuild target with source dependency when previous target exists, after the
source dependency has been modified, but the source dependency timestamp and
size is the same as last time. (Based on e03.)
EOF

init_test
mkdir  fix
cpdir .fix src build

# Replace 'src/SOURCE.txt' but keep its old timestamp and filesize.
timestamp SOURCEDEP src/SOURCE.txt
write_file src/SOURCE.txt <<-"END_SOURCE"
	XXXXXXXXXXXXXX
END_SOURCE
reset_timestamp "$SOURCEDEP"

write_file a+x fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "PRE"
	$FIX --source SOURCE.txt
	cat "$FIX_SOURCE_DIR/SOURCE.txt"
	echo "POST"
END_SCRIPT

OUTPUT="PRE
XXXXXXXXXXXXXX
POST"

timestamp TARGET        build/TARGET
timestamp METADATA .fix/state/TARGET

file_exists     build/TARGET         "Before build: Target should exist"
file_exists     .fix/state/TARGET    "Before build: Metadata file should exist"

"$TESTCMD" TARGET >stdout 2>stderr; RC="$?"

DBDATA="$(
    set -e
    mkmetadata TARGET TARGET     <build/TARGET
    # mkmetadata SCRIPT TARGET.fix <fix/TARGET.fix  # TODO script dep
    # mkmetadata SOURCE SOURCE.txt <src/SOURCE.txt  # TODO source dep
)" || fail "Failed to calculate metadata"

is              "$RC"                0             "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$NADA"       "Standard error"
file_is         build/TARGET         "$OUTPUT"     "Target"
is_changed      "$TARGET"                          "Target timestamp"
file_is         .fix/state/TARGET    "$DBDATA"     "Metadata"
is_changed      "$METADATA"                        "Metadata timestamp"
file_not_exists build/TARGET--fixing               "Target tempfile shouldn't exist"

done_testing

#[eof]
