#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2016 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Test that the --source-dir option sets $FIX_SOURCE_DIR value for the
buildscripts.
EOF

init_test
mkdir .fix src2

write_file a+x fix/ZERO.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "ZERO: $FIX_SOURCE_DIR"
	fix --source SOURCE.txt
	cat "$FIX_SOURCE_DIR/SOURCE.txt"
END_SCRIPT

write_file src2/SOURCE.txt <<-"END_SOURCE"
	SOURCE CONTENT
END_SOURCE

OUTPUT="ZERO: $PWD/src2
SOURCE CONTENT"

file_not_exists build/ZERO            "Before build: Target ZERO shouldn't exist"
file_not_exists .fix/state/ZERO       "Before build: Metadata ZERO shouldn't exist"
file_exists     src2/SOURCE.txt       "Before build: Source should exist"
file_not_exists .fix/state/SOURCE.txt "Before build: Source metadata shouldn't exist"

"$TESTCMD" build/ZERO >stdout 2>stderr --source-dir=src2; RC="$?"

META_ZERO="$(
    set -e
    mkmetadata TARGET ZERO       <build/ZERO
    mkmetadata SCRIPT ZERO.fix   <fix/ZERO.fix
    mkmetadata SOURCE SOURCE.txt <src2/SOURCE.txt
)" || fail "Failed to calculate metadata"

is              "$RC"                0             "Exit status"
file_not_exists src                                "Default source dir shouldn't exist"
file_exists     src2                               "Source dir should exist"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$NADA"       "Standard error"

file_is         build/ZERO           "$OUTPUT"     "Target ZERO content"
file_not_exists build/ZERO--fixing                 "Target ZERO tempfile shouldn't exist"
file_is         .fix/state/ZERO      "$META_ZERO"  "Target ZERO metadata"
first_dep_is    .fix/state/ZERO      "ZERO"        "Target ZERO metadata first target"
file_not_exists .fix/state/ZERO--fixing            "Target ZERO metadata tempfile shouldn't exist"

done_testing

#[eof]
