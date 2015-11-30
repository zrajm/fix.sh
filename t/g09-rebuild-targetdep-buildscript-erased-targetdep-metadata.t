#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Rebuild target with a target dependency, when previous target and dependency
target exists, but the metadata for the dependency target has been erased.
EOF

init_test
mkdir fix src

############################################################################
## Dependency Target

write_file a+x 2030-01-01 fix/DEPTARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "DEPENDENCY"
END_SCRIPT

DEP_OUTPUT="DEPENDENCY"
DEP_META="$(
    set -e
    echo "$DEP_OUTPUT" | mkmetadata TARGET DEPTARGET
    <fix/DEPTARGET.fix   mkmetadata SCRIPT DEPTARGET.fix
)" || fail "Failed to calculate metadata"

echo "$DEP_OUTPUT" | write_file build/DEPTARGET

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
$DEP_OUTPUT
POST"
META="$(
    set -e
    echo "$OUTPUT"     | mkmetadata TARGET TARGET
    <fix/TARGET.fix      mkmetadata SCRIPT TARGET.fix
    echo "$DEP_OUTPUT" | mkmetadata TARGET DEPTARGET
)" || fail "Failed to calculate metadata"

echo "$OUTPUT" | write_file build/TARGET
echo "$META"   | write_file .fix/state/TARGET

############################################################################

# Don't check metadata timestamp (only content is relevant).
timestamp TARGET      build/TARGET
timestamp DEPTARGET   build/DEPTARGET

prefix "Before build"
file_exists     build/TARGET                  "Target should exist"
file_exists     fix/TARGET.fix                "Target buildscript should exist"
file_is         .fix/state/TARGET    "$META"  "Target metadata"
first_dep_is    .fix/state/TARGET    "TARGET" "Target metadata target first"
file_exists     build/DEPTARGET               "Dependency target should exist"
file_exists     fix/DEPTARGET.fix             "Dependency buildscript should exist"
file_not_exists .fix/state/DEPTARGET          "Dependency metadata shouldn't exist"
end_prefix

"$TESTCMD" TARGET >stdout 2>stderr; RC="$?"

is              "$RC"                0             "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$NADA"       "Standard error"

# Command line target.
file_is         build/TARGET         "$OUTPUT"     "Target"
is_unchanged    "$TARGET"                          "Target timestamp"
file_is         .fix/state/TARGET    "$META"       "Target metadata"
file_not_exists .fix/state/TARGET--fixing          "Target metadata tempfile shouldn't exist"
file_not_exists build/TARGET--fixing               "Target tempfile"

# Dependency target.
file_is         build/DEPTARGET         "$DEP_OUTPUT" "Dependency target"
is_unchanged    "$DEPTARGET"                          "Dependency target timestamp"
file_is         .fix/state/DEPTARGET    "$DEP_META"   "Dependency metadata"
file_not_exists .fix/state/DEPTARGET--fixing          "Dependency metadata tempfile shouldn't exist"
file_not_exists build/DEPTARGET--fixing               "Dependency target tempfile"

done_testing

#[eof]
