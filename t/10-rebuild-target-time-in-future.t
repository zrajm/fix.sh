#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
note <<EOF
Rebuild target that has already been built after target file's timestamp have
been moved into the future. (Based on 07.)
EOF

init_test fix src
write_file a+x -1sec fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "OUTPUT"
END_SCRIPT
write_file 2030-01-01 build/TARGET <<-"END_TARGET"
	OUTPUT
END_TARGET

TARGET="$(timestamp build/TARGET)"
METADATA="$(timestamp .fix/state/TARGET)"

"$TESTCMD" TARGET >stdout 2>stderr
is              $?                   0             "Exit status"
file_is         stdout               ""            "Standard output"
file_is         stderr               ""            "Standard error"
file_not_exist  build/TARGET--fixing               "Target tempfile shouldn't exist"
file_is         build/TARGET         "OUTPUT"      "Target"
is_unchanged    "$TARGET"                          "Target timestamp"
file_exist      .fix/state/TARGET                  "Metadata file"
is_unchanged    "$METADATA"                        "Metadata timestamp"

done_testing

#[eof]
