#!/usr/bin/env dash
# -*- sh -*-
. "t/test-functions.sh"

note <<EOF
07: Attempt to build target with buildscript that returns zero exit status.
EOF

ERRMSG=""

CMD="../../fix.sh"
cd "${0%.t}"
trap "rm -fr stdout stderr build" 0
$CMD TARGET >stdout 2>stderr
is              $?                   0             "Exit status"
file_is         stdout               ""            "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"
file_not_exist  build/TARGET--fixing               "Target tempfile shouldn't exist"
file_is         build/TARGET         "SOME OUTPUT" "Target"
file_exist      .fix/TARGET                        "Metadata file"

done_testing

#[eof]
