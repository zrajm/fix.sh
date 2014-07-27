#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
title - <<"EOF"
Attempt to build target with a source dependency that have its read bits unset.
EOF

init_test
mkdir fix src

write_file a-r src/SOURCE.txt <<-"END_SOURCE"
	SOURCE
END_SOURCE

write_file a+x fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "PRE"
	FIX_SOURCE=yes $FIX SOURCE.txt
	cat "$FIX_SOURCE_DIR/SOURCE.txt"
	echo "POST"
END_SCRIPT

ERRMSG="ERROR: No read permission for source file 'src/SOURCE.txt'
ERROR: Cannot find source dependency needed by buildscript 'fix/TARGET.fix'"

file_not_exists build/TARGET         "Before build: Target shouldn't exist"
file_not_exists .fix/state/TARGET    "Before build: Metadata file shouldn't exist"

"$TESTCMD" TARGET >stdout 2>stderr
is              $?                   10            "Exit status # TODO"
file_is         stdout               "$NADA"       "Standard output"
TODO
file_is         stderr               "$ERRMSG"     "Standard error"
file_not_exists build/TARGET                       "Target shouldn't exist"
file_not_exists .fix/state/TARGET                  "Metadata file shouldn't exist"
file_is         build/TARGET--fixing "PRE"         "Target tempfile"

done_testing

#[eof]
