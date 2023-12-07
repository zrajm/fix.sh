#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "dashtap/dashtap.sh"
title - <<"EOF"
Rebuild target with source dependency when previous target exists, after the
source dependency has been modified. (Based on e03.)
EOF

init_test
mkdir  fix src
cpdir .fix build

write_file src/SOURCE.txt <<-"END_SOURCE"
	SOURCE CONTENT TOO
END_SOURCE

write_file a+x fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "PRE"
	fix --source SOURCE.txt
	cat "$FIX_SOURCE_DIR/SOURCE.txt"
	echo "POST"
END_SCRIPT

OUTPUT="PRE
SOURCE CONTENT TOO
POST"

# Don't check metadata timestamp (only content is relevant).
timestamp TARGET        build/TARGET

file_exists     build/TARGET         "Before build: Target should exist"
file_exists     .fix/state/TARGET    "Before build: Metadata file should exist"

"$TESTCMD" build/TARGET >stdout 2>stderr; RC="$?"

DBDATA="$(
    set -e
    mkmetadata TARGET TARGET     <build/TARGET
    mkmetadata SCRIPT TARGET.fix <fix/TARGET.fix
    mkmetadata SOURCE SOURCE.txt <src/SOURCE.txt
)" || fail "Failed to calculate metadata"

is              "$RC"                0             "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$NADA"       "Standard error"
file_is         build/TARGET         "$OUTPUT"     "Target"
is_changed      "$TARGET"                          "Target timestamp"
file_is         .fix/state/TARGET    "$DBDATA"     "Target metadata"
first_dep_is    .fix/state/TARGET    "TARGET"      "Target metadata target first"
file_not_exists .fix/state/TARGET--fixing          "Target metadata tempfile shouldn't exist"
file_not_exists build/TARGET--fixing               "Target tempfile shouldn't exist"

done_testing

#[eof]
