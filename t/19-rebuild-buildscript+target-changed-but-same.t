#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
note <<EOF
Rebuild target when previous target exist and is modified, but buildscript is
also modified and builds a target identical to modified the modified one.
EOF

init_test fix src
write_file fix/TARGET.fix a+x <<-"END_SCRIPT"
	#!/bin/sh
	echo "OUTPUT2"
END_SCRIPT
write_file build/TARGET <<-"END_TARGET"
	OUTPUT2
END_TARGET

TARGET="$(timestamp build/TARGET)"
METADATA="$(timestamp .fix/state/TARGET)"

# FIXME: don't sleep if timestamp has sub-second precision
sleep 1

"$TESTCMD" TARGET >stdout 2>stderr
is              $?                   0             "Exit status"
file_is         stdout               ""            "Standard output"
file_is         stderr               ""            "Standard error"
file_is         build/TARGET         "OUTPUT2"     "Target"
is_unchanged    "$TARGET"                          "Target timestamp"
file_exist      .fix/state/TARGET                  "Metadata file"
is_changed      "$METADATA"                        "Metadata timestamp"
file_not_exist  build/TARGET--fixing               "Target tempfile shouldn't exist"

done_testing

#[eof]
