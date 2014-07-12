#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
note <<EOF
Rebuild target after buildscript modified (by a comment or similar) in such a
way that it still produces the same output as it previously did. (Based on 07.)
EOF

init_test fix src
write_file fix/TARGET.fix a+x <<-"END_SCRIPT"
	#!/bin/sh
	# added comment
	echo "OUTPUT"
END_SCRIPT
write_file build/TARGET <<-"END_TARGET"
	OUTPUT
END_TARGET

TARGET="$(timestamp build/TARGET)"
METADATA="$(timestamp .fix/state/TARGET)"

# FIXME: don't sleep if timestamp has sub-second precision
sleep 1

"$TESTCMD" TARGET >stdout 2>stderr
is              $?                   0             "Exit status"
file_is         stdout               ""            "Standard output"
file_is         stderr               ""            "Standard error"
file_is         build/TARGET         "OUTPUT"      "Target"
is_unchanged    "$TARGET"                          "Target timestamp"
file_exist      .fix/state/TARGET                  "Metadata file"
is_unchanged    "$METADATA"                        "Metadata timestamp"
file_not_exist  build/TARGET--fixing               "Target tempfile shouldn't exist"

done_testing

#[eof]
