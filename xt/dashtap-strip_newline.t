#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
NADA=""; strip_newline NADA                    # NADA = '\No newline at end'

is "$(type strip_newline)" "strip_newline is a shell function" \
    "Function 'strip_newline' exists"

##############################################################################

cd "$(mktemp -d)"
STDERR="strip_newline: Too many args"
note "strip_newline with too many args"
execute <<"EOF" trap >out 2>err
    LINE=""
    strip_newline LINE B C
    echo "$LINE"
EOF
is        $?        255        "Exit status"
file_is   out       "$NADA"    "Standard output"
file_is   err       "$STDERR"  "Standard error"
file_is   trap      "EXIT"     "Called exit"

##############################################################################

cd "$(mktemp -d)"
STDERR="strip_newline: Bad VARNAME 'BAD-VAR'"
note "strip_newline with bad variable name"
execute <<"EOF" trap >out 2>err
    strip_newline "BAD-VAR"
    echo "$BAD-VAR"
EOF
is        $?        255        "Exit status"
file_is   out       "$NADA"    "Standard output"
file_is   err       "$STDERR"  "Standard error"
file_is   trap      "EXIT"     "Called exit"

##############################################################################

cd "$(mktemp -d)"
STDOUT="\\No newline at end"
note "strip_newline with zero length string"
execute <<"EOF" trap >out 2>err
    LINE=""
    strip_newline LINE
    echo "$LINE"
EOF
is        $?        0          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
STDOUT="Hello\\No newline at end"
note "strip_newline with string not ending in newline"
execute <<"EOF" trap >out 2>err
    LINE="Hello"
    strip_newline LINE
    echo "$LINE"
EOF
is        $?        0          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
STDOUT="  1  2  spaces  \\No newline at end"
note "strip_newline with string leading + trailing spaces"
execute <<"EOF" trap >out 2>err
    LINE="  1  2  spaces  "
    strip_newline LINE
    echo "$LINE"
EOF
is        $?        0          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
STDOUT="Hello"
note "strip_newline with string ending in newline"
execute <<"EOF" trap >out 2>err
    LINE="Hello
"
    strip_newline LINE
    echo "$LINE"
EOF
is        $?        0          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

done_testing

#[eof]
