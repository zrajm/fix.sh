#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
NADA=""; strip_newline NADA                    # NADA = '\No newline at end'

##############################################################################

function_exists         match        "Function 'match' exists"

##############################################################################

cd "$(mktemp -d)"
execute "match '*' 'ABC*'" trapout >stdout 2>stderr
is           $?         0            "Exit status with match"
file_is      stdout     "$NADA"      "Standard output"
file_is      stderr     "$NADA"      "Standard error"
file_is      trapout    "FULL"       "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
execute "match '*' 'ABC'" trapout >stdout 2>stderr
is           $?         1            "Exit status without match"
file_is      stdout     "$NADA"      "Standard output"
file_is      stderr     "$NADA"      "Standard error"
file_is      trapout    "FULL"       "Didn't call exit"

##############################################################################

done_testing

#[eof]
