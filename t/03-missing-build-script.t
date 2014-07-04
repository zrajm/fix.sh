#!/usr/bin/env dash
# -*- sh -*-
. "t/test-functions.sh"

note <<EOF
03: Attempt to build target when there is no build script for it.
EOF

ERRMSG="ERROR: Buildscript 'fix/TARGET.fix' does not exist"

CMD="../../fix.sh"
cd "${0%.t}"
trap "rm -fr stdout stderr build" 0
$CMD TARGET >stdout 2>stderr
is              $?                   10            "Exit status"
file_is         stdout               ""            "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"
file_not_exist  build/TARGET--fixing               "Target tempfile shouldn't exist"
file_not_exist  build/TARGET                       "Target shouldn't exist"

done_testing

#[eof]