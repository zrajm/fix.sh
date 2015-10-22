#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
title - <<"EOF"
Attempt to build target with buildscript that returns non-zero exit status.
EOF

init_test
mkdir fix src

write_file a+x fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "OUTPUT"
	exit 1
END_SCRIPT

ERRMSG="ERROR: Buildscript 'fix/TARGET.fix' returned exit status 1
    (Old target unchanged. New, failed target written to 'build/TARGET--fixing'.)"

file_not_exists build/TARGET         "Before build: Target shouldn't exist"
file_not_exists .fix/state/TARGET    "Before build: Metadata file shouldn't exist"

"$TESTCMD" TARGET >stdout 2>stderr; RC="$?"

is              "$RC"                5             "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"
file_not_exists build/TARGET                       "Target shouldn't exist"
file_not_exists .fix/state/TARGET                  "Metadata file shouldn't exist"
file_is         build/TARGET--fixing "OUTPUT"      "Target tempfile"

done_testing

#[eof]
