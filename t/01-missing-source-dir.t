#!/usr/bin/env dash
# -*- sh -*-
. "t/test-functions.sh"

note <<EOF
01: Attempt to build target when there is no source dir.
EOF

ERRMSG="ERROR: Source dir 'src' does not exist"

CMD="../../fix.sh"
cd "${0%.t}"
trap "rm -f stdout stderr" 0
$CMD TARGET >stdout 2>stderr
is              $?                   10            "Exit status"
file_is         stdout               ""            "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"
file_not_exist  build/TARGET--fixing               "Target tempfile shouldn't exist"
file_not_exist  build/TARGET                       "Target shouldn't exist"

done_testing

#[eof]
