#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Should fail to rebuild a target when one of its dependencies has a target file
that has been manually modified by the user.
EOF

init_test
mkdir  fix src
cpdir .fix

############################################################################
## Dependency Target

write_file a+x fix/DEPTARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "DEPENDENCY"
END_SCRIPT

# Deptaget content written by user.
write_file build/DEPTARGET <<-"END_TARGET"
	DEP-MODDED
END_TARGET

# Metadata for old dependency target.
DEP_DBDATA="$(
    set -e
    echo "DEPENDENCY" | mkmetadata TARGET DEPTARGET
    # mkmetadata SCRIPT TARGET.fix <fix/TARGET.fix  # TODO script dep
)" || fail "Failed to calculate metadata"

echo "$DEP_DBDATA" | write_file .fix/state/DEPTARGET

############################################################################
## Target

write_file a+x fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "PRE"
	$FIX DEPTARGET
	cat "$FIX_TARGET_DIR/DEPTARGET"
	echo "POST"
END_SCRIPT

OUTPUT="PRE
DEPENDENCY
POST"
echo "$OUTPUT" | write_file build/TARGET

# Metadata for old dependency target.
DBDATA="$(
    set -e
    echo "$OUTPUT" | mkmetadata TARGET TARGET
    # mkmetadata SCRIPT TARGET.fix <fix/TARGET.fix  # TODO script dep
)" || fail "Failed to calculate metadata"

echo "$DBDATA" | write_file .fix/state/TARGET

ERRMSG="ERROR: Old target 'build/DEPTARGET' modified by user, won't overwrite
    (Erase old target before rebuild. New target kept in 'build/DEPTARGET--fixing'.)
ERROR: Buildscript 'fix/TARGET.fix' returned exit status 143
    (Old target unchanged. New, failed target written to 'build/TARGET--fixing'.)"

timestamp TARGET      build/TARGET
timestamp METADATA    .fix/state/TARGET
timestamp DEPTARGET   build/DEPTARGET
timestamp DEPMETADATA .fix/state/DEPTARGET

file_exists build/TARGET         "Before build: Target should exist"
file_exists .fix/state/TARGET    "Before build: Metadata file should exist"

file_exists build/DEPTARGET      "Before build: Dependency target should exist"
file_exists .fix/state/DEPTARGET "Before build: Dependency metadata file should exist"

"$TESTCMD" TARGET >stdout 2>stderr; RC="$?"

is              "$RC"                1             "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"

# Dependency target.
file_is         build/DEPTARGET         "DEP-MODDED"  "Dependency target"
is_unchanged    "$DEPTARGET"                          "Dependency target timestamp"
file_is         .fix/state/DEPTARGET    "$DEP_DBDATA" "Dependency metadata"
is_unchanged    "$METADATA"                           "Dependency metadata timestamp"
file_is         build/DEPTARGET--fixing "DEPENDENCY"  "Dependency target tempfile"

# Command line target.
file_is         build/TARGET         "$OUTPUT"     "Target"
is_unchanged    "$TARGET"                          "Target timestamp"
file_is         .fix/state/TARGET    "$DBDATA"     "Metadata"
is_unchanged    "$METADATA"                        "Metadata timestamp"
file_is         build/TARGET--fixing "PRE"         "Target tempfile"

done_testing

#[eof]
