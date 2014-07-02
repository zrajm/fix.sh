#!/usr/bin/env dash
# -*- sh -*-
. "t/test-functions.sh"

cat <<"EOF" | note
06: Attempt to build target with buildscript that returns non-zero exit status.
EOF

ERRMSG="ERROR: Buildscript 'fix/TARGET.fix' returned exit status 1
    (Old target unchanged. New, failed target written to 'build/TARGET--fixing'.)"

CMD="../../fix.sh"
cd "${0%.t}"
trap "rm -fr stdout stderr build" 0
$CMD TARGET >stdout 2>stderr
has_exit_status 5                                  "Exit status"
file_is         stdout               ""            "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"
file_is         build/TARGET--fixing "SOME OUTPUT" "Target tempfile"
file_not_exist  build/TARGET                       "Target shouldn't exist"

done_testing

#[eof]
