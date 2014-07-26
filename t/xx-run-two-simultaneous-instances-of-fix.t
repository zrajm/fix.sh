#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
note <<"EOF"
Attempt to run two copies of fix at once. First instance should build, second
instance should detect lockfile and refuse to start.
EOF

init_test
mkdir  fix src .fix
mkfifo fifo                                        # buildscript reads fifo

write_file a+x fix/TARGET.fix <<"END_SCRIPT"
	#!/bin/sh
	read LINE <fifo
	echo "$LINE"
END_SCRIPT

ERRMSG="ERROR: Cannot create lockfile '.fix/lock.pid'
    (Is fix.sh is already running? Is lockfile dir writeable?)"

## First instance of fix: This is run in the background, and has a buildscript
## that reads from a fifo, causing the buildscript to hang until something is
## written to that fifo.
"$TESTCMD" TARGET >stdout1 2>stderr1 &
PID=$!                                             # PID of 1st instance
sleep .1

## Second instance of fix: This should fail immediately since the first
## instance should have established a lockfile.
"$TESTCMD" TARGET >stdout2 2>stderr2
is              $?                   8             "Blocked's exit status"
file_is         stdout2              "$NADA"       "Blocked's standard output"
file_is         stderr2              "$ERRMSG"     "Blocked's standard error"

## This fifo is read by the buildscript (which is currently just hanging,
## waiting for input) when we write to it the buildscript will write this input
## to the target, and finish (thereby exiting the first instance of fix).
echo PIPED >fifo

## Wait for the first instance fix to terminate, then test its output to see
## that it wasn't disturbed somehow.
wait "$PID"
is              $?                   0             "Exit status"
file_is         stdout1              "$NADA"       "Standard output"
file_is         stderr1              "$NADA"       "Standard error"
file_not_exists build/TARGET--fixing               "Target tempfile shouldn't exist"
file_is         build/TARGET         "PIPED"       "Target"
file_exists     .fix/state/TARGET                  "Metadata file"

done_testing

#[eof]
