#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
title - <<"EOF"
Rebuild target with source dependency that has already been built after source
dependency file's timestamp have been moved into the future. (Based on e03.)
EOF

init_test
mkdir  fix src
cpdir .fix

write_file 2030-01-01 src/SOURCE.txt <<-"END_SOURCE"
	SOURCE CONTENT
END_SOURCE

write_file a+x fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "PRE"
	FIX_SOURCE=yes $FIX SOURCE.txt
	cat "$FIX_SOURCE_DIR/SOURCE.txt"
	echo "POST"
END_SCRIPT

OUTPUT="PRE
SOURCE CONTENT
POST"

timestamp TARGET        build/TARGET
timestamp METADATA .fix/state/TARGET

TODO
file_exists          build/TARGET    "Before build: Target should exist"
file_exists     .fix/state/TARGET    "Before build: Metadata file should exist"
END_TODO

"$TESTCMD" TARGET >stdout 2>stderr; RC="$?"

is              "$RC"                0             "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$NADA"       "Standard error"
file_is         build/TARGET         "$OUTPUT"     "Target"
is_unchanged    "$TARGET"                          "Target timestamp # TODO"
file_exists     .fix/state/TARGET                  "Metadata file should exist"
is_unchanged    "$METADATA"                        "Metadata timestamp # TODO"
file_not_exists build/TARGET--fixing               "Target tempfile shouldn't exist"

done_testing

#[eof]
