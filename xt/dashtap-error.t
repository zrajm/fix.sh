#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
cd "$(mktemp -d)"

##############################################################################

# FIXME: test function existance of 'error' first
(
    trap 'echo EXITED >trapout; trap - 0' 0
    error "AA BB" >stdout 2>stderr
    STATUS=$?
    trap 'echo RETURNED >trapout; trap - 0' 0
    exit $STATUS
)
is        $?        255        "Exit status"
file_is   stdout    ""         "Standard output"
file_is   stderr    "AA BB"    "Standard error"
file_is   trapout   "EXITED"   "Call exit (don't return)"

##############################################################################

(
    trap 'echo EXITED >trapout; trap - 0' 0
    error >stdout 2>stderr
    STATUS=$?
    trap 'echo RETURNED >trapout; trap - 0' 0
    exit $STATUS
)
is        $?        255        "Exit status"
file_is   stdout    ""         "Standard output"
file_is   stderr    ""         "Standard error"
file_is   trapout   "EXITED"   "Call exit (don't return)"

##############################################################################

done_testing

#[eof]
