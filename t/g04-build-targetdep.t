#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Should successfully build target with target dependency, when built in a clean
work tree.
EOF

init_test
mkdir .fix fix src

############################################################################
## Dependency Target

write_file a+x fix/DEPTARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "DEPENDENCY"
END_SCRIPT

DEP_OUTPUT="DEPENDENCY"
DEP_META="$(
    set -e
    echo "$DEP_OUTPUT" | mkmetadata TARGET DEPTARGET
    <fix/DEPTARGET.fix   mkmetadata SCRIPT DEPTARGET.fix
)" || fail "Failed to calculate metadata"

############################################################################
## Target

write_file a+x fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "PRE"
	fix DEPTARGET
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

############################################################################

prefix "Before build"
file_not_exists build/TARGET         "Target shouldn't exist"
file_exists     fix/TARGET.fix       "Target buildscript should exist"
file_not_exists .fix/state/TARGET    "Target metadata shouldn't exist"
file_not_exists .fix/state/TARGET--fixing          "Target metadata tempfile shouldn't exist"
file_not_exists build/DEPTARGET      "Dependency target shouldn't exist"
file_exists     fix/DEPTARGET.fix    "Dependency buildscript should exist"
file_not_exists .fix/state/DEPTARGET "Dependency metadata shouldn't exist"
end_prefix

"$TESTCMD" TARGET >stdout 2>stderr; RC="$?"

is              "$RC"                0             "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$NADA"       "Standard error"

# Command line target.
file_is         build/TARGET         "$OUTPUT"     "Target"
file_is         .fix/state/TARGET    "$META"       "Target metadata"
first_dep_is    .fix/state/TARGET    "TARGET"      "Target metadata target first"
file_not_exists build/TARGET--fixing               "Target tempfile"

# Dependency target.
file_is         build/DEPTARGET         "DEPENDENCY"  "Dependency target"
file_is         .fix/state/DEPTARGET    "$DEP_META"   "Dependency metadata"
first_dep_is    .fix/state/DEPTARGET    "DEPTARGET"   "Target metadata target first"
file_not_exists build/DEPTARGET--fixing               "Dependency target tempfile"

done_testing

#[eof]
