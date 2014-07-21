#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
NADA=""; strip_newline NADA                    # NADA = '\No newline at end'

##############################################################################

function_exists     error      "Function 'error' exists"

##############################################################################

cd "$(mktemp -d)"
execute "error 'AA BB'" trapout >stdout 2>stderr
is        $?        255        "Exit status"
file_is   stdout    "$NADA"    "Standard output"
file_is   stderr    "AA BB"    "Standard error"
file_is   trapout   "EXIT"     "Called exit"

##############################################################################

cd "$(mktemp -d)"
execute "error" trapout >stdout 2>stderr
is        $?        255        "Exit status"
file_is   stdout    "$NADA"    "Standard output"
file_is   stderr    "$NADA"    "Standard error"
file_is   trapout   "EXIT"     "Called exit"

##############################################################################

done_testing

#[eof]
