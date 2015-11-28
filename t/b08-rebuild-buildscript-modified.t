#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Rebuild target when previous target exists, but the buildscript has been
modified so that it outputs something new. (Based on b02.)
EOF

init_test
mkdir  fix src
cpdir .fix

write_file a+x -1sec fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "OUTPUT2"
END_SCRIPT
write_file -1sec build/TARGET <<-"END_TARGET"
	OUTPUT
END_TARGET

timestamp TARGET        build/TARGET
timestamp METADATA .fix/state/TARGET

file_exists     build/TARGET         "Before build: Target should exist"
file_exists     .fix/state/TARGET    "Before build: Metadata file should exist"

"$TESTCMD" TARGET >stdout 2>stderr; RC="$?"

DBDATA="$(
    set -e
    mkmetadata TARGET TARGET     <build/TARGET
    mkmetadata SCRIPT TARGET.fix <fix/TARGET.fix
)" || fail "Failed to calculate metadata"

is              "$RC"                0             "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$NADA"       "Standard error"
file_is         build/TARGET         "OUTPUT2"     "Target"
is_changed      "$TARGET"                          "Target timestamp"
file_is         .fix/state/TARGET    "$DBDATA"     "Metadata"
is_changed      "$METADATA"                        "Metadata timestamp"
file_not_exists build/TARGET--fixing               "Target tempfile shouldn't exist"

done_testing

#[eof]
