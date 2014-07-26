#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
note <<"EOF"
Attempt to build target with buildscript with read bits unset.
EOF

init_test
mkdir fix src

write_file a-r fix/TARGET.fix
ERRMSG="ERROR: No read permission for buildscript 'fix/TARGET.fix'"

"$TESTCMD" TARGET >stdout 2>stderr
is              $?                   10            "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"
file_not_exists build/TARGET                       "Target shouldn't exist"
file_not_exists .fix/state/TARGET                  "Metadata file shouldn't exist"
file_not_exists build/TARGET--fixing               "Target tempfile shouldn't exist"

done_testing

#[eof]
