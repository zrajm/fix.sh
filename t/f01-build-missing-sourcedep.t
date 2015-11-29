#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Attempt to build a target for which there is a missing source dependency.
EOF

init_test
mkdir fix src

write_file a+x fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "PRE"
	$FIX --source SOURCE.txt
	cat "$FIX_SOURCE_DIR/SOURCE.txt"
	echo "POST"
END_SCRIPT

ERRMSG="ERROR: Source file 'src/SOURCE.txt' does not exist
ERROR: Cannot find source dependency needed by buildscript 'fix/TARGET.fix'"

file_not_exists build/TARGET         "Before build: Target shouldn't exist"
file_not_exists .fix/state/TARGET    "Before build: Metadata file shouldn't exist"

"$TESTCMD" TARGET >stdout 2>stderr; RC="$?"

is              "$RC"                10            "Exit status # TODO"
file_is         stdout               "$NADA"       "Standard output"
TODO
file_is         stderr               "$ERRMSG"     "Standard error"
file_not_exists build/TARGET                       "Target shouldn't exist"
file_not_exists .fix/state/TARGET                  "Metadata file shouldn't exist"
file_is         build/TARGET--fixing "PRE"         "Target tempfile"

done_testing

#[eof]
