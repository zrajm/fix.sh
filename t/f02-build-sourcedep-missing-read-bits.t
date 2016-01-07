#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Attempt to build target with a source dependency that have its read bits unset.
EOF

init_test
mkdir .fix fix src

write_file a-r src/SOURCE.txt <<-"END_SOURCE"
	SOURCE
END_SOURCE

write_file a+x fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "PRE"
	fix --source SOURCE.txt
	cat "$FIX_SOURCE_DIR/SOURCE.txt"
	echo "POST"
END_SCRIPT

ERRMSG="ERROR: No read permission for source file 'src/SOURCE.txt'
ERROR: Buildscript 'fix/TARGET.fix' returned exit status 143
    (Old target unchanged. New, failed target written to 'build/TARGET--fixing'.)"

file_not_exists build/TARGET         "Before build: Target shouldn't exist"
file_not_exists .fix/state/TARGET    "Before build: Metadata file shouldn't exist"

"$TESTCMD" build/TARGET >stdout 2>stderr; RC="$?"

is              "$RC"                1             "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"
file_not_exists build/TARGET                       "Target shouldn't exist"
file_not_exists .fix/state/TARGET                  "Metadata file shouldn't exist"
file_is         build/TARGET--fixing "PRE"         "Target tempfile"

done_testing

#[eof]
