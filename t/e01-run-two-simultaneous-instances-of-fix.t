#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Attempt to run two copies of fix at once. First instance should build, second
instance should detect lockfile and refuse to start.
EOF

init_test
mkdir  fix src .fix
mkfifo fifo                                        # buildscript reads fifo

write_file a+x fix/TARGET.fix <<"END_SCRIPT"
	#!/bin/sh
	read LINE <"$FIX_WORK_TREE/fifo"
	echo "$LINE"
END_SCRIPT

ERRMSG="ERROR: Cannot create lockfile '$PWD/.fix/lock.pid'
    (Is fix.sh is already running? Is lockfile dir writeable?)"

file_not_exists build/TARGET         "Before build: Target shouldn't exist"
file_not_exists .fix/state/TARGET    "Before build: Metadata file shouldn't exist"

## First instance of fix: This is run in the background, and has a buildscript
## that reads from a fifo, causing the buildscript to hang until something is
## written to that fifo.
"$TESTCMD" TARGET >stdout1 2>stderr1 &

PID="$!"                                           # PID of 1st instance
sleep .1

file_exists build/TARGET--fixing          "1st build should create tempfile"
timestamp TEMPFILE build/TARGET--fixing

## Second instance of fix: This should fail immediately since the first
## instance should have established a lockfile.
"$TESTCMD" TARGET >stdout2 2>stderr2 &
PID2=$!
# Set up a background process that will wait for two seconds before killing the
# second instance of fix.
{ sleep 2; kill "$PID2" 2>/dev/null; } >&- 2>&- &
wait "$PID2"; RC="$?"

is              "$RC"                8             "2nd build's exit status"
file_is         stdout2              "$NADA"       "2nd build's standard output"
file_is         stderr2              "$ERRMSG"     "2nd build's standard error"
file_not_exists build/TARGET         "2nd build shouldn't create build target"
file_not_exists .fix/state/TARGET    "2nd build shouldn't create metadata file"
file_not_exists .fix/state/TARGET--fixing          "Target metadata tempfile shouldn't exist"
is_unchanged    "$TEMPFILE"          "1st build's tempfile should be unchanged"

## This fifo is read by the buildscript (which is currently just hanging,
## waiting for input) when we write to it the buildscript will write this input
## to the target, and finish (thereby exiting the first instance of fix).
echo PIPED >fifo

## Wait for the first instance fix to terminate, then test its output to see
## that it wasn't disturbed somehow.
wait "$PID"; RC="$?"

DBDATA="$(
    set -e
    echo "PIPED"     | mkmetadata TARGET TARGET
     <fix/TARGET.fix   mkmetadata SCRIPT TARGET.fix
)" || fail "Failed to calculate metadata"

is              "$RC"                0             "2nd build exit status"
file_is         stdout1              "$NADA"       "2nd build standard output"
file_is         stderr1              "$NADA"       "2nd build standard error"
file_is         build/TARGET         "PIPED"       "2nd build target"
file_is         .fix/state/TARGET    "$DBDATA"     "2nd build metadata"
first_dep_is    .fix/state/TARGET    "TARGET"      "Target metadata target first"
file_not_exists .fix/state/TARGET--fixing          "Target metadata tempfile shouldn't exist"
file_not_exists build/TARGET--fixing "2nd build shouldn't create tempfile"

done_testing

#[eof]
