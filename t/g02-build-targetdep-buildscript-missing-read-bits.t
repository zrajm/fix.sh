#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Attempt to build a target with a target dependency, where the target dependency
buildscript does not have read bits.
EOF

init_test
mkdir .fix fix src

############################################################################
## Dependency Target

write_file a-r fix/DEPTARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "DEPENDENCY"
END_SCRIPT

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

ERRMSG="ERROR: No read permission for buildscript 'fix/DEPTARGET.fix'
ERROR: Buildscript 'fix/TARGET.fix' returned exit status 143
    (Old target unchanged. New, failed target written to 'build/TARGET--fixing'.)"

############################################################################

prefix "Before build"
file_not_exists build/TARGET         "Target shouldn't exist"
file_exists     fix/TARGET.fix       "Target buildscript should exist"
file_not_exists .fix/state/TARGET    "Target metadata shouldn't exist"
file_not_exists build/DEPTARGET      "Dependency target shouldn't exist"
file_exists     fix/DEPTARGET.fix    "Dependency buildscript should exist"
file_not_exists .fix/state/DEPTARGET "Dependency metadata shouldn't exist"
end_prefix

"$TESTCMD" TARGET >stdout 2>stderr; RC="$?"

is              "$RC"                1             "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"

# Command line target.
file_not_exists build/TARGET                       "Target"
file_not_exists .fix/state/TARGET                  "Target metadata"
file_is         build/TARGET--fixing    "PRE"      "Target tempfile"

# Dependency target.
file_not_exists build/DEPTARGET                    "Dependency target"
file_not_exists .fix/state/DEPTARGET               "Dependency metadata"
file_not_exists build/DEPTARGET--fixing            "Dependency target tempfile"

done_testing

#[eof]
