#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
note <<EOF
Build target with buildscript that returns zero exit status.
EOF

init_test fix src
write_file fix/TARGET.fix a+x <<-"END_SCRIPT"
	#!/bin/sh
	echo "OUTPUT"
END_SCRIPT

"$TESTCMD" TARGET >stdout 2>stderr
is              $?                   0             "Exit status"
file_is         stdout               ""            "Standard output"
file_is         stderr               ""            "Standard error"
file_is         build/TARGET         "OUTPUT"      "Target"
file_exist      .fix/state/TARGET                  "Metadata file"
file_not_exist  build/TARGET--fixing               "Target tempfile shouldn't exist"

done_testing

#[eof]
