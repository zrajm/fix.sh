#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
cd "$(mktemp -d)"

# Usage: run_function CMD TRAPFILE
#
# Evals CMD, saving to TRAPFILE whether the command(s) exited ('EXIT'), or ran
# all the way through ('ALL'). This can be used to invoke a function and see
# whether it returned properly ('ALL') or called exit.
#
# Exit status will be the same as the exit status of the terminating command in
# CMD (if 'exit' was called, this is be whatever exit status 'exit' gave).
run_function() {
    local CMD="$1" TRAPFILE="$2"
    (
        trap "echo EXIT >$TRAPFILE; trap - 0" 0
        eval "$CMD"
        STATUS=$?
        trap "echo FULL >$TRAPFILE; trap - 0" 0
        exit $STATUS
    )
}

##############################################################################

is "$(type match)" "match is a shell function" "Function 'match' exists"

run_function "match '*' 'ABC*'" trapout
is           $?         0            "Exit status with match"
file_is      trapout    "RETURN"     "Returned"

run_function "match '*' 'ABC'" trapout
is           $?         1            "Exit status without match"
file_is      trapout    "RETURN"     "Returned"

done_testing

#[eof]
