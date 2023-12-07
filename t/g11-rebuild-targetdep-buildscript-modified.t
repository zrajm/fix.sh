#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "dashtap/dashtap.sh"
title - <<"EOF"
Rebuild target with a target dependency when previous target exists, after the
dependency target buildscript has been modified.
EOF

init_test
mkdir fix src

############################################################################
## Dependency Target

write_file a+x fix/DEPTARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "NEW DEPENDENCY"
END_SCRIPT

OLD_DEP_OUTPUT="DEPENDENCY"
NEW_DEP_OUTPUT="NEW DEPENDENCY"
OLD_DEP_META="$(
    set -e
    echo "$OLD_DEP_OUTPUT" | mkmetadata TARGET DEPTARGET
    <<-"END_SCRIPT"          mkmetadata SCRIPT DEPTARGET.fix # old buildscript
	#!/bin/sh
	set -eu
	echo "DEPENDENCY"
	END_SCRIPT
)" || fail "Failed to calculate metadata"
NEW_DEP_META="$(
    set -e
    echo "$NEW_DEP_OUTPUT" | mkmetadata TARGET DEPTARGET
    <fix/DEPTARGET.fix       mkmetadata SCRIPT DEPTARGET.fix
)" || fail "Failed to calculate metadata"

echo "$OLD_DEP_OUTPUT" | write_file build/DEPTARGET
echo "$OLD_DEP_META"   | write_file .fix/state/DEPTARGET

############################################################################
## Target

write_file a+x fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "PRE"
	fix DEPTARGET
	cat "$FIX_TARGET_DIR/DEPTARGET"
	echo "POST"
END_SCRIPT

OLD_OUTPUT="PRE
$OLD_DEP_OUTPUT
POST"
NEW_OUTPUT="PRE
$NEW_DEP_OUTPUT
POST"
OLD_META="$(
    set -e
    echo "$OLD_OUTPUT"     | mkmetadata TARGET TARGET
    <fix/TARGET.fix          mkmetadata SCRIPT TARGET.fix
    echo "$OLD_DEP_OUTPUT" | mkmetadata TARGET DEPTARGET
)" || fail "Failed to calculate metadata"
NEW_META="$(
    set -e
    echo "$NEW_OUTPUT"     | mkmetadata TARGET TARGET
    <fix/TARGET.fix          mkmetadata SCRIPT TARGET.fix
    echo "$NEW_DEP_OUTPUT" | mkmetadata TARGET DEPTARGET
)" || fail "Failed to calculate metadata"

echo "$OLD_OUTPUT" | write_file build/TARGET
echo "$OLD_META"   | write_file .fix/state/TARGET

############################################################################

# Don't check metadata timestamp (only content is relevant).
timestamp TARGET      build/TARGET
timestamp DEPTARGET   build/DEPTARGET

prefix "Before build"
file_exists  build/TARGET                         "Target should exist"
file_exists  fix/TARGET.fix                       "Target buildscript should exist"
file_is      .fix/state/TARGET    "$OLD_META"     "Target metadata"
first_dep_is .fix/state/TARGET    "TARGET"        "Target metadata target first"
file_exists  build/DEPTARGET                      "Dependency target should exist"
file_exists  fix/DEPTARGET.fix                    "Dependency buildscript should exist"
file_is      .fix/state/DEPTARGET "$OLD_DEP_META" "Dependency metadata"
end_prefix

"$TESTCMD" build/TARGET >stdout 2>stderr; RC="$?"

is              "$RC"                0             "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$NADA"       "Standard error"

# Command line target.
file_is         build/TARGET         "$NEW_OUTPUT"     "Target"
is_changed      "$TARGET"                              "Target timestamp"
file_is         .fix/state/TARGET    "$NEW_META"       "Target metadata"
file_not_exists .fix/state/TARGET--fixing              "Target metadata tempfile shouldn't exist"
file_not_exists build/TARGET--fixing                   "Target tempfile"

# Dependency target.
file_is         build/DEPTARGET      "$NEW_DEP_OUTPUT" "Dependency target"
is_changed      "$DEPTARGET"                           "Dependency target timestamp"
file_is         .fix/state/DEPTARGET "$NEW_DEP_META"   "Dependency metadata"
file_not_exists .fix/state/DEPTARGET--fixing           "Dependency metadata tempfile shouldn't exist"
file_not_exists build/DEPTARGET--fixing                "Dependency target tempfile"

done_testing

#[eof]
