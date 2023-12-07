#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "dashtap/dashtap.sh"
title - <<"EOF"
Attempt to build target with buildscript with execute bits unset.
EOF

init_test
mkdir .fix fix src

write_file fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "NEVER RUN"
END_SCRIPT

ERRMSG="ERROR: No execute permission for buildscript 'fix/TARGET.fix'"

file_not_exists build/TARGET         "Before build: Target shouldn't exist"
file_not_exists .fix/state/TARGET    "Before build: Metadata file shouldn't exist"

"$TESTCMD" build/TARGET >stdout 2>stderr; RC="$?"

is              "$RC"                1             "Exit status"
file_is         stdout               "$NADA"       "Standard output"
file_is         stderr               "$ERRMSG"     "Standard error"
file_not_exists build/TARGET                       "Target shouldn't exist"
file_not_exists .fix/state/TARGET                  "Metadata file shouldn't exist"
file_not_exists build/TARGET--fixing               "Target tempfile shouldn't exist"

done_testing

#[eof]
