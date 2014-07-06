#!/usr/bin/env dash
# -*- sh -*-
. "t/test-functions.sh"
note <<EOF
07: Attempt to build target with buildscript that returns zero exit status.
EOF

init_test fix src
write_file fix/TARGET.fix a+x <<-"END_SCRIPT"
	#!/bin/sh
	echo "OUTPUT"
END_SCRIPT

ERRMSG=""

"$TESTCMD" TARGET >stdout 2>stderr
is              $?                   0             "Exit status"
file_is         stdout               ""            "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"
file_not_exist  build/TARGET--fixing               "Target tempfile shouldn't exist"
file_is         build/TARGET         "OUTPUT"      "Target"
file_exist      .fix/state/TARGET                  "Metadata file"

done_testing

#[eof]
