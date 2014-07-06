#!/usr/bin/env dash
# -*- sh -*-
. "t/test-functions.sh"
note <<EOF
06: Attempt to build target with buildscript that returns non-zero exit status.
EOF

init_test fix src
write_file fix/TARGET.fix a+x <<-"END_SCRIPT"
	#!/bin/sh
	echo "OUTPUT"
	exit 1
END_SCRIPT

ERRMSG="ERROR: Buildscript 'fix/TARGET.fix' returned exit status 1
    (Old target unchanged. New, failed target written to 'build/TARGET--fixing'.)"

"$TESTCMD" TARGET >stdout 2>stderr
is              $?                   5             "Exit status"
file_is         stdout               ""            "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"
file_is         build/TARGET--fixing "OUTPUT"      "Target tempfile"
file_not_exist  build/TARGET                       "Target shouldn't exist"

done_testing

#[eof]
