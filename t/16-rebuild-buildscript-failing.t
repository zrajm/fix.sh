#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
note <<EOF
Attempt to rebuild target after buildscript have been changed so that it now
fails. (Based on 07.)
EOF

init_test fix src
write_file fix/TARGET.fix -1sec a+x <<-"END_SCRIPT"
	#!/bin/sh
	echo "OUTPUT2"
	exit 1
END_SCRIPT
write_file build/TARGET -1sec <<-"END_TARGET"
	OUTPUT
END_TARGET

ERRMSG="ERROR: Buildscript 'fix/TARGET.fix' returned exit status 1
    (Old target unchanged. New, failed target written to 'build/TARGET--fixing'.)"

TARGET="$(timestamp build/TARGET)"
METADATA="$(timestamp .fix/state/TARGET)"

"$TESTCMD" TARGET >stdout 2>stderr
is              $?                   5             "Exit status"
file_is         stdout               ""            "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"
file_is         build/TARGET         "OUTPUT"      "Target"
is_unchanged    "$TARGET"                          "Target timestamp"
file_exist      .fix/state/TARGET                  "Metadata file"
is_unchanged    "$METADATA"                        "Metadata timestamp"
file_is         build/TARGET--fixing "OUTPUT2"     "Target tempfile"

done_testing

#[eof]
