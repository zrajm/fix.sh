#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Attempt to rebuild target when previous target exist but have no metadata
stored, and the newly built target differs from the old target.
EOF

init_test
mkdir fix src

############################################################################
## Dependency Target

write_file a+x fix/DEPTARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "NEW DEPENDENCY"
END_SCRIPT

OLD_DEP_OUTPUT="DEPENDENCY"
NEW_DEP_OUTPUT="NEW DEPENDENCY"

echo "$OLD_DEP_OUTPUT" | write_file build/DEPTARGET

############################################################################
## Target

write_file a+x fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "PRE"
	fix DEPTARGET
	cat "$FIX_TARGET_DIR/DEPTARGET"
	echo "POST"
END_SCRIPT

OLD_OUTPUT="PRE
$OLD_DEP_OUTPUT
POST"
OLD_META="$(
    set -e
    echo "$OLD_OUTPUT"     | mkmetadata TARGET TARGET
    echo "$OLD_DEP_OUTPUT" | mkmetadata TARGET DEPTARGET
)" || fail "Failed to calculate metadata"

echo "$OLD_OUTPUT" | write_file build/TARGET
echo "$OLD_META"   | write_file .fix/state/TARGET

ERRMSG="ERROR: Old target 'build/DEPTARGET' modified by user, won't overwrite
    (Erase old target before rebuild. New target kept in 'build/DEPTARGET--fixing'.)
ERROR: Buildscript 'fix/TARGET.fix' returned exit status 143
    (Old target unchanged. New, failed target written to 'build/TARGET--fixing'.)"

############################################################################

# Don't check metadata timestamp (only content is relevant).
timestamp TARGET      build/TARGET
timestamp DEPTARGET   build/DEPTARGET

prefix "Before build"
file_exists     build/TARGET                     "Target should exist"
file_exists     fix/TARGET.fix                   "Target buildscript should exist"
file_is         .fix/state/TARGET    "$OLD_META" "Target metadata"
first_dep_is    .fix/state/TARGET    "TARGET"    "Target metadata target first"
file_exists     build/DEPTARGET                  "Dependency target should exist"
file_exists     fix/DEPTARGET.fix                "Dependency buildscript should exist"
file_not_exists .fix/state/DEPTARGET             "Dependency metadata shouldn't exist"
end_prefix

"$TESTCMD" TARGET >stdout 2>stderr; RC="$?"

is              "$RC"                1             "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"

# Command line target.
file_is         build/TARGET         "$OLD_OUTPUT"     "Target"
is_unchanged    "$TARGET"                              "Target timestamp"
file_is         .fix/state/TARGET    "$OLD_META"       "Target metadata"
file_not_exists .fix/state/TARGET--fixing              "Target metadata tempfile shouldn't exist"
file_is         build/TARGET--fixing "PRE"             "Target tempfile"

# Dependency target.
file_is         build/DEPTARGET      "$OLD_DEP_OUTPUT" "Dependency target"
is_unchanged    "$DEPTARGET"                           "Dependency target timestamp"
file_not_exists .fix/state/DEPTARGET                   "Dependency metadata"
file_not_exists .fix/state/DEPTARGET--fixing           "Dependency metadata tempfile shouldn't exist"
file_is         build/DEPTARGET--fixing "$NEW_DEP_OUTPUT" "Dependency target tempfile"

done_testing

#[eof]
