#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Should successfully rebuild target with a target dependency which in turn has a
target dependency when a previous build target exists, after the leafnode
target dependency buildscript has been modified to produce new output.
EOF

init_test
mkdir fix src

############################################################################
## Leaf Dependency Target

write_file a+x fix/LEAFTARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "NEW LEAF"
END_SCRIPT

OLD_LEAF_OUTPUT="LEAF"
NEW_LEAF_OUTPUT="NEW LEAF"
OLD_LEAF_META="$(
    set -e
    echo "$OLD_LEAF_OUTPUT" | mkmetadata TARGET LEAFTARGET
    <<-"END_SCRIPT"           mkmetadata SCRIPT LEAFTARGET.fix # old buildscript
	#!/bin/sh
	echo "LEAF"
	END_SCRIPT
)" || fail "Failed to calculate metadata"
NEW_LEAF_META="$(
    set -e
    echo "$NEW_LEAF_OUTPUT" | mkmetadata TARGET LEAFTARGET
    <fix/LEAFTARGET.fix       mkmetadata SCRIPT LEAFTARGET.fix
)" || fail "Failed to calculate metadata"

echo "$OLD_LEAF_OUTPUT" | write_file build/LEAFTARGET
echo "$OLD_LEAF_META"   | write_file .fix/state/LEAFTARGET

############################################################################
## Dependency Target

write_file a+x fix/DEPTARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	fix LEAFTARGET
	cat "$FIX_TARGET_DIR/LEAFTARGET"
	echo "DEP"
END_SCRIPT

OLD_DEP_OUTPUT="$OLD_LEAF_OUTPUT
DEP"
NEW_DEP_OUTPUT="$NEW_LEAF_OUTPUT
DEP"
OLD_DEP_META="$(
    set -e
    echo "$OLD_DEP_OUTPUT"  | mkmetadata TARGET DEPTARGET
    <fix/DEPTARGET.fix        mkmetadata SCRIPT DEPTARGET.fix
    echo "$OLD_LEAF_OUTPUT" | mkmetadata TARGET LEAFTARGET
)" || fail "Failed to calculate metadata"
NEW_DEP_META="$(
    set -e
    echo "$NEW_DEP_OUTPUT"  | mkmetadata TARGET DEPTARGET
    <fix/DEPTARGET.fix        mkmetadata SCRIPT DEPTARGET.fix
    echo "$NEW_LEAF_OUTPUT" | mkmetadata TARGET LEAFTARGET
)" || fail "Failed to calculate metadata"

echo "$OLD_DEP_OUTPUT" | write_file build/DEPTARGET
echo "$OLD_DEP_META"   | write_file .fix/state/DEPTARGET

############################################################################
## Target

write_file a+x fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	fix DEPTARGET
	cat "$FIX_TARGET_DIR/DEPTARGET"
	echo "TARGET"
END_SCRIPT

OLD_OUTPUT="$OLD_DEP_OUTPUT
TARGET"
NEW_OUTPUT="$NEW_DEP_OUTPUT
TARGET"
OLD_META="$(
    set -e
    echo "$OLD_OUTPUT"     | mkmetadata TARGET TARGET
    <fix/TARGET.fix          mkmetadata SCRIPT TARGET.fix
    echo "$OLD_DEP_OUTPUT" | mkmetadata TARGET TARGET
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
timestamp LEAFTARGET  build/LEAFTARGET

prefix "Before build"
file_exists  build/TARGET                           "Target should exist"
file_exists  fix/TARGET.fix                         "Target buildscript should exist"
file_is      .fix/state/TARGET     "$OLD_META"      "Target metadata"
first_dep_is .fix/state/TARGET     "TARGET"         "Target metadata target first"
file_exists  build/DEPTARGET                        "Dependency target should exist"
file_exists  fix/DEPTARGET.fix                      "Dependency target buildscript should exist"
file_is      .fix/state/DEPTARGET  "$OLD_DEP_META"  "Dependency target metadata"
first_dep_is .fix/state/DEPTARGET  "DEPTARGET"      "Dependency target metadata target first"
file_exists  build/LEAFTARGET                       "Leaf target should exist"
file_exists  fix/LEAFTARGET.fix                     "Leaf buildscript should exist"
file_is      .fix/state/LEAFTARGET "$OLD_LEAF_META" "Leaf metadata"
end_prefix

"$TESTCMD" TARGET >stdout 2>stderr; RC="$?"

is              "$RC"                0             "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$NADA"       "Standard error"

# Command line target.
file_is         build/TARGET         "$NEW_OUTPUT"     "Target"
is_changed      "$TARGET"                              "Target timestamp"
file_is         .fix/state/TARGET    "$NEW_META"       "Target metadata"
file_not_exists .fix/state/TARGET--fixing              "Target metadata tempfile"
file_not_exists build/TARGET--fixing                   "Target tempfile"

# Dependency target.
file_is         build/DEPTARGET      "$NEW_DEP_OUTPUT" "Dependency target"
is_changed      "$DEPTARGET"                           "Dependency target timestamp"
file_is         .fix/state/DEPTARGET "$NEW_DEP_META"   "Dependency metadata"
file_not_exists .fix/state/DEPTARGET--fixing           "Dependency metadata tempfile"
file_not_exists build/DEPTARGET--fixing                "Dependency target tempfile"

# Leaf dependency target.
file_is         build/LEAFTARGET      "$NEW_LEAF_OUTPUT" "Leaf target"
is_changed      "$LEAFTARGET"                            "Leaf target timestamp"
file_is         .fix/state/LEAFTARGET "$NEW_LEAF_META"   "Leaf metadata"
file_not_exists .fix/state/LEAFTARGET--fixing            "Leaf metadata tempfile"
file_not_exists build/LEAFTARGET--fixing                 "Leaf target tempfile"

done_testing

#[eof]
