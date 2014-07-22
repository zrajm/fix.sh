#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
NADA=""; strip_newline NADA                    # NADA = '\No newline at end'

##############################################################################

function_exists         match        "Function 'match' exists"

##############################################################################

cd "$(mktemp -d)"
note "match: Fail when more than two args are used"
STDERR="match: Bad number of args"
execute <<"EOF" trapout >stdout 2>stderr
    match TOO MANY ARGS
EOF
is           $?         255          "Exit status"
file_is      stdout     "$NADA"      "Standard output"
file_is      stderr     "$STDERR"    "Standard error"
file_is      trapout    "EXIT"       "Called exit"

##############################################################################

cd "$(mktemp -d)"
note "match: Fail when called with no args"
STDERR="match: Bad number of args"
execute <<"EOF" trapout >stdout 2>stderr
    match
EOF
is           $?         255          "Exit status"
file_is      stdout     "$NADA"      "Standard output"
file_is      stderr     "$STDERR"    "Standard error"
file_is      trapout    "EXIT"       "Called exit"

##############################################################################

cd "$(mktemp -d)"
note "match: Ignore STDIN when two args are used"
execute <<"EOF" trapout >stdout 2>stderr
    echo "STDIN" | match "ARG" "ARG"
EOF
is           $?         0            "Exit status"
file_is      stdout     "$NADA"      "Standard output"
file_is      stderr     "$NADA"      "Standard error"
file_is      trapout    "FULL"       "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
note "match: Process STDIN when one arg is used"
execute <<"EOF" trapout >stdout 2>stderr
    echo "STDIN" | match "STDIN"
EOF
is           $?         0            "Exit status"
file_is      stdout     "$NADA"      "Standard output"
file_is      stderr     "$NADA"      "Standard error"
file_is      trapout    "FULL"       "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
note "match: Fail to find '*' when missing in string"
execute <<"EOF" trapout >stdout 2>stderr
    match "*" "ABC"
EOF
is           $?         1            "Exit status without match"
file_is      stdout     "$NADA"      "Standard output"
file_is      stderr     "$NADA"      "Standard error"
file_is      trapout    "FULL"       "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
note "match: Find '*' last in string"
execute <<"EOF" trapout >stdout 2>stderr
    match "*" "AB*"
EOF
is           $?         0            "Exit status"
file_is      stdout     "$NADA"      "Standard output"
file_is      stderr     "$NADA"      "Standard error"
file_is      trapout    "FULL"       "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
note "match: Find '*' in middle of string"
execute <<"EOF" trapout >stdout 2>stderr
    match "*" "A*C"
EOF
is           $?         0            "Exit status"
file_is      stdout     "$NADA"      "Standard output"
file_is      stderr     "$NADA"      "Standard error"
file_is      trapout    "FULL"       "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
note "match: Find '*' at beginning of string"
execute <<"EOF" trapout >stdout 2>stderr
    match "*" "*BC"
EOF
is           $?         0            "Exit status"
file_is      stdout     "$NADA"      "Standard output"
file_is      stderr     "$NADA"      "Standard error"
file_is      trapout    "FULL"       "Didn't call exit"

##############################################################################

done_testing

#[eof]
