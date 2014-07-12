#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
note <<EOF
Attempt to rebuild target when previous target exist and is modified. (Based on
07.)
EOF

init_test fix src
write_file fix/TARGET.fix a+x <<-"END_SCRIPT"
	#!/bin/sh
	echo "OUTPUT"
END_SCRIPT
write_file build/TARGET <<-"END_TARGET"
	OUTPUT2
END_TARGET

ERRMSG="ERROR: Old target 'build/TARGET' modified by user, won't overwrite
    (Erase old target before rebuild. New target kept in 'build/TARGET--fixing'.)"

TARGET="$(timestamp build/TARGET)"
METADATA="$(timestamp .fix/state/TARGET)"

# FIXME: don't sleep if timestamp has sub-second precision
sleep 1

"$TESTCMD" TARGET >stdout 2>stderr
is              $?                   1             "Exit status"
file_is         stdout               ""            "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"
file_is         build/TARGET         "OUTPUT2"     "Target"
is_unchanged    "$TARGET"                          "Target timestamp"
file_exist      .fix/state/TARGET                  "Metadata file"
is_unchanged    "$METADATA"                        "Metadata timestamp"
file_is         build/TARGET--fixing "OUTPUT"      "Target tempfile"

done_testing

#[eof]
