#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
NADA=""; strip_newline NADA                    # NADA = '\No newline at end'

is "$(type setread)" "setread is a shell function" "Function 'setread' exists"

##############################################################################

cd "$(mktemp -d)"
note "setread: Bad variable name"
STDERR="setread: Bad VARNAME ''"
execute <<"EOF" trap >out 2>err
    setread ""
EOF
is        $?        255        "Exit status"
file_is   out       "$NADA"    "Standard output"
file_is   err       "$STDERR"  "Standard error"
file_is   trap      "EXIT"     "Called exit"

##############################################################################

cd "$(mktemp -d)"
note "setread: Too many args"
STDERR="setread: Too many args"
execute <<"EOF" trap >out 2>err
    setread too many args
EOF
is        $?        255        "Exit status"
file_is   out       "$NADA"    "Standard output"
file_is   err       "$STDERR"  "Standard error"
file_is   trap      "EXIT"     "Called exit"

##############################################################################

cd "$(mktemp -d)"
note "setread: No input"
execute <<"EOF" trap >out 2>err
    X=""
    setread X
    echo "$X"
EOF
is        $?        0          "Exit status"
file_is   out       "$NADA"    "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
note "setread: On previously set variable"
execute <<"EOF" trap >out 2>err
    X="STRING"
    setread X
    echo "$X"
EOF
is        $?        0          "Exit status"
file_is   out       "$NADA"    "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
note "setread: Input with space and quotes"
VAR="  '   \"  "
execute <<"EOF" trap >out 2>err
    X=""
    setread X <<-"END_SETREAD"
	  '   "  
	END_SETREAD
    echo "$X"
EOF
is        $?        0          "Exit status"
file_is   out       "$VAR"     "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

# FIXME: Test for 'setread' where input does not end in newline

done_testing

#[eof]
