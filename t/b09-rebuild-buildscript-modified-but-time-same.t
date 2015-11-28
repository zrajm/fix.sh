#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Rebuild target when previous target exists, and the buildscript has been
modified, but the buildscript timestamp and size is the same as last time.
(Based on b02.)
EOF

init_test
mkdir  src
cpdir .fix fix

# Replace 'fix/TARGET.fix' but keep its old timestamp and filesize.
timestamp BUILDSCRIPT fix/TARGET.fix
write_file a+x fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "6BYTES"   # same length as 'OUTPUT'
END_SCRIPT
reset_timestamp "$BUILDSCRIPT"

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
file_is         build/TARGET         "6BYTES"      "Target"
is_changed      "$TARGET"                          "Target timestamp"
file_is         .fix/state/TARGET    "$DBDATA"     "Metadata"
is_changed      "$METADATA"                        "Metadata timestamp"
file_not_exists build/TARGET--fixing               "Target tempfile shouldn't exist"

done_testing

#[eof]
