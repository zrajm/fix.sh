#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
note <<EOF
Attempt to rebuild target that has already been built after target's metadata
file's timestamp have been moved into the past. (Based on 07.)
EOF

init_test fix src
write_file fix/TARGET.fix a+x <<-"END_SCRIPT"
	#!/bin/sh
	echo "OUTPUT"
END_SCRIPT
write_file build/TARGET <<-"END_TARGET"
	OUTPUT
END_TARGET
chtime 2000-01-01 .fix/state/TARGET

TARGET="$(timestamp build/TARGET)"
METADATA="$(timestamp .fix/state/TARGET)"

# FIXME: don't sleep if timestamp has sub-second precision
sleep 1

"$TESTCMD" TARGET >stdout 2>stderr
file_is         stdout               ""            "Standard output"
file_is         stderr               ""            "Standard error"
file_is         build/TARGET         "OUTPUT"      "Target"
is_unchanged    "$TARGET"                          "Target timestamp"
file_exist      .fix/state/TARGET                  "Metadata file"
is_unchanged    "$METADATA"                        "Metadata timestamp"
file_not_exist  build/TARGET--fixing               "Target tempfile shouldn't exist"

done_testing

#[eof]
