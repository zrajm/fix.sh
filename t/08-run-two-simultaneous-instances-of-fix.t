#!/usr/bin/env dash
# -*- sh -*-
. "t/test-functions.sh"

note <<EOF
08: Attempt to run two copies of fix at once. First instance should build,
    second instance should detect lockfile and refuse to start.
EOF

ERRMSG="ERROR: Cannot create lockfile '.fix/lock.pid'
    (Is fix.sh is already running? Is lockfile dir writeable?)"

CMD="../../fix.sh"
cd "${0%.t}"
trap "rm -fr stdout1 stderr1 stdout2 stderr2 fifo build .fix" 0

# The buildscript reads from this fifo.
[ -p fifo ] || mkfifo fifo

## First instance of fix: This is run in the background, and has a buildscript
## that reads from a fifo, causing the buildscript to hang until something is
## written to that fifo.
$CMD TARGET >stdout1 2>stderr1 &

PID=$!                                             # PID of 1st instance

sleep .5

## Second instance of fix: This should fail immediately since the first
## instance should have established a lockfile.
$CMD TARGET >stdout2 2>stderr2
is              $?                   8             "Blocked's exit status"
file_is         stdout2              ""            "Blocked's standard output"
file_is         stderr2              "$ERRMSG"     "Blocked's standard error"


## This fifo is read by the buildscript (which is currently just hanging,
## waiting for input) when we write to it the buildscript will write this input
## to the target, and finish (thereby exiting the first instance of fix).
echo PIPESTRING >fifo

## Wait for the first instance fix to terminate, then test its output to see
## that it wasn't disturbed somehow.
wait "$PID"
is              $?                   0             "Exit status"
file_is         stdout1              ""            "Standard output"
file_is         stderr1              ""            "Standard error"
file_not_exist  build/TARGET--fixing               "Target tempfile shouldn't exist"
file_is         build/TARGET         "PIPESTRING"  "Target"
file_exist      .fix/TARGET                        "Metadata file"

done_testing

#[eof]
