#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
title - <<"EOF"
Attempt to declare source dependency outside of a buildscript (i.e. using
'--source' option from the command line).
EOF

init_test
mkdir fix src

write_file fix/TARGET.fix
ERRMSG="ERROR: Option '--source' can only be used inside buildscript"

file_not_exists build/TARGET         "Before build: Target shouldn't exist"
file_not_exists .fix/state/TARGET    "Before build: Metadata file shouldn't exist"

FIX_SOURCE=yes "$TESTCMD" TARGET >stdout 2>stderr; RC="$?"

is              "$RC"                15            "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"
file_not_exists build/TARGET                       "Target shouldn't exist"
file_not_exists .fix/state/TARGET                  "Metadata file shouldn't exist"
file_not_exists build/TARGET--fixing               "Target tempfile shouldn't exist"

done_testing

#[eof]
