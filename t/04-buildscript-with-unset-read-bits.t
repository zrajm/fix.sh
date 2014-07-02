#!/usr/bin/env dash
# -*- sh -*-
. "t/test-functions.sh"

cat <<"EOF" | note
04: Attempt to build target with buildscript with read bits unset.
EOF

ERRMSG="ERROR: No read permission for buildscript 'fix/TARGET.fix'"

CMD="../../fix.sh"
cd "${0%.t}"
trap "rm -fr stdout stderr build; chmod -f u+r fix/TARGET.fix" 0
chmod -f u-r fix/TARGET.fix                        # disable read bits
$CMD TARGET >stdout 2>stderr
has_exit_status 10                                 "Exit status"
file_is         stdout               ""            "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"
file_not_exist  build/TARGET--fixing               "Target tempfile shouldn't exist"
file_not_exist  build/TARGET                       "Target shouldn't exist"

done_testing

#[eof]
