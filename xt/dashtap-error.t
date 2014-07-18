#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"

is "$(type error)" "error is a shell function" "Function 'error' exists"

##############################################################################

cd "$(mktemp -d)"
execute "error 'AA BB'" trapout >stdout 2>stderr
is        $?        255        "Exit status"
file_is   stdout    ""         "Standard output"
file_is   stderr    "AA BB"    "Standard error"
file_is   trapout   "EXIT"     "Called exit"

##############################################################################

cd "$(mktemp -d)"
execute "error" trapout >stdout 2>stderr
is        $?        255        "Exit status"
file_is   stdout    ""         "Standard output"
file_is   stderr    ""         "Standard error"
file_is   trapout   "EXIT"     "Called exit"

##############################################################################

done_testing

#[eof]
