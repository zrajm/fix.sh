#!/usr/bin/env dash
# -*- sh -*-
. "t/test-functions.sh"

note <<EOF
05: Attempt to build target with buildscript with execute bits unset.
EOF

ERRMSG="ERROR: No execute permission for buildscript 'fix/TARGET.fix'"

CMD="../../fix.sh"
cd "${0%.t}"
trap "rm -fr stdout stderr build; chmod -f u+x fix/TARGET.fix" 0
chmod -f u-x fix/TARGET.fix                        # disable execute bits
$CMD TARGET >stdout 2>stderr
is              $?                   10            "Exit status"
file_is         stdout               ""            "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"
file_not_exist  build/TARGET--fixing               "Target tempfile shouldn't exist"
file_not_exist  build/TARGET                       "Target shouldn't exist"

done_testing

#[eof]
