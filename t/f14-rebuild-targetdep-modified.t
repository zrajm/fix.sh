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
mkdir fix src

############################################################################
## Dependency Target

write_file a+x fix/DEPTARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "DEPENDENCY"
END_SCRIPT

OLD_DEP_OUTPUT="DEPENDENCY"
NEW_DEP_OUTPUT="NEW DEPENDENCY"
OLD_DEP_META="$(
    set -e
    echo "$OLD_DEP_OUTPUT" | mkmetadata TARGET DEPTARGET
)" || fail "Failed to calculate metadata"

echo "$NEW_DEP_OUTPUT" | write_file build/DEPTARGET
echo "$OLD_DEP_META"   | write_file .fix/state/DEPTARGET

############################################################################
## Target

write_file a+x fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "PRE"
	$FIX DEPTARGET
	cat "$FIX_TARGET_DIR/DEPTARGET"
	echo "POST"
END_SCRIPT

OLD_OUTPUT="PRE
$OLD_DEP_OUTPUT
POST"
OLD_META="$(
    set -e
    echo "$OLD_OUTPUT"         | mkmetadata TARGET TARGET
    echo "$OLD_DEP_OUTPUT" | mkmetadata TARGET DEPTARGET
)" || fail "Failed to calculate metadata"

echo "$OLD_OUTPUT" | write_file build/TARGET
echo "$OLD_META"   | write_file .fix/state/TARGET

ERRMSG="ERROR: Old target 'build/DEPTARGET' modified by user, won't overwrite
    (Erase old target before rebuild. New target kept in 'build/DEPTARGET--fixing'.)
ERROR: Buildscript 'fix/TARGET.fix' returned exit status 143
    (Old target unchanged. New, failed target written to 'build/TARGET--fixing'.)"

############################################################################

# Don't check timestamps for metadata (only content is relevant).
timestamp TARGET      build/TARGET
timestamp DEPTARGET   build/DEPTARGET
timestamp METADATA    .fix/state/TARGET
timestamp DEPMETADATA .fix/state/DEPTARGET

prefix "Before build"
file_exists  build/TARGET                         "Target should exist"
file_exists  fix/TARGET.fix                       "Target buildscript should exist"
file_is      .fix/state/TARGET    "$OLD_META"     "Target metadata"
first_dep_is .fix/state/TARGET    "TARGET"        "Target metadata target first"
file_exists  build/DEPTARGET                      "Dependency target should exist"
file_exists  fix/DEPTARGET.fix                    "Dependency buildscript should exist"
file_is      .fix/state/DEPTARGET "$OLD_DEP_META" "Dependency metadata"
end_prefix

"$TESTCMD" TARGET >stdout 2>stderr; RC="$?"

is              "$RC"                1             "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"

# Command line target.
file_is         build/TARGET         "$OLD_OUTPUT" "Target"
is_unchanged    "$TARGET"                          "Target timestamp"
file_is         .fix/state/TARGET    "$OLD_META"   "Metadata"
is_unchanged    "$METADATA"                        "Metadata timestamp"
file_is         build/TARGET--fixing "PRE"         "Target tempfile"

# Dependency target.
file_is         build/DEPTARGET         "$NEW_DEP_OUTPUT" "Dependency target"
is_unchanged    "$DEPTARGET"                              "Dependency target timestamp"
file_is         .fix/state/DEPTARGET    "$OLD_DEP_META"   "Dependency metadata"
is_unchanged    "$DEPMETADATA"                            "Dependency metadata timestamp"
file_is         build/DEPTARGET--fixing "DEPENDENCY"      "Dependency target tempfile"

done_testing

#[eof]
