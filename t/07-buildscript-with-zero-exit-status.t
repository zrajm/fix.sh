#!/usr/bin/env dash
# -*- sh -*-
. "t/test-functions.sh"

cat <<"EOF" | note
07: Attempt to build target with buildscript that returns zero exit status.
EOF

ERRMSG=""

CMD="../../fix.sh"
cd "${0%.t}"
trap "rm -fr stdout stderr build" 0
$CMD TARGET >stdout 2>stderr
has_exit_status 0                                  "Exit status"
file_is         stdout               ""            "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"
file_not_exist  build/TARGET--fixing               "Target tempfile shouldn't exist"
file_is         build/TARGET         "SOME OUTPUT" "Target"

done_testing

#[eof]
