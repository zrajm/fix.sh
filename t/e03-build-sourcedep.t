#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Build target with source dependency.
EOF

init_test
mkdir fix src

write_file src/SOURCE.txt <<-"END_SOURCE"
	SOURCE CONTENT
END_SOURCE

write_file a+x fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "PRE"
	$FIX --source SOURCE.txt
	cat "$FIX_SOURCE_DIR/SOURCE.txt"
	echo "POST"
END_SCRIPT

OUTPUT="PRE
SOURCE CONTENT
POST"

file_not_exists build/TARGET         "Before build: Target shouldn't exist"
file_not_exists .fix/state/TARGET    "Before build: Metadata file shouldn't exist"

"$TESTCMD" TARGET >stdout 2>stderr; RC="$?"

DBDATA="$(
    set -e
    mkmetadata TARGET TARGET     <build/TARGET
    mkmetadata SCRIPT TARGET.fix <fix/TARGET.fix
    # mkmetadata SOURCE SOURCE.txt <src/SOURCE.txt  # TODO source dep
)" || fail "Failed to calculate metadata"

is              "$RC"                0             "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$NADA"       "Standard error"
file_is         build/TARGET         "$OUTPUT"     "Target"
file_is         .fix/state/TARGET    "$DBDATA"     "Metadata"
file_not_exists build/TARGET--fixing               "Target tempfile shouldn't exist"

done_testing

#[eof]
