#!/usr/bin/env dash
# -*- sh -*-
. "t/test-functions.sh"
note <<EOF
Rebuild target after buildscript have been changed so that it outputs something
new. (Based on 07.)
EOF

init_test fix src
write_file fix/TARGET.fix a+x <<-"END_SCRIPT"
	#!/bin/sh
	echo "OUTPUT2"
	exit 1
END_SCRIPT
write_file build/TARGET <<-"END_TARGET"
	OUTPUT
END_TARGET

ERRMSG="ERROR: Buildscript 'fix/TARGET.fix' returned exit status 1
    (Old target unchanged. New, failed target written to 'build/TARGET--fixing'.)"
TARG_STAT="$(timestamp build/TARGET)"
META_STAT="$(timestamp .fix/state/TARGET)"

# FIXME: don't sleep if timestamp has sub-second precision
sleep 1

"$TESTCMD" TARGET >stdout 2>stderr
is              $?                   5             "Exit status"
file_is         stdout               ""            "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"
file_is         build/TARGET--fixing "OUTPUT2"     "Target tempfile"
file_is         build/TARGET         "OUTPUT"      "Target"
is_unchanged    "$TARG_STAT"                       "Target timestamp"
file_exist      .fix/state/TARGET                  "Metadata file"
is_unchanged    "$META_STAT"                       "Metadata timestamp"

done_testing

#[eof]
