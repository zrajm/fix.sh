#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
NADA=""; strip_newline NADA                    # NADA = '\No newline at end'

##############################################################################

function_exists     seteval    "Function 'seteval' exists"

##############################################################################

cd "$(mktemp -d)"
note "Bad variable name"
STDERR="seteval: Bad VARNAME ''"
execute <<EOF trap >out 2>err
    seteval ""
EOF
is        $?        255        "Exit status"
file_is   out       "$NADA"    "Standard output"
file_is   err       "$STDERR"  "Standard error"
file_is   trap      "EXIT"     "Called exit"

##############################################################################

cd "$(mktemp -d)"
note "Too many args"
STDERR="seteval: Too many args"
execute <<EOF trap >out 2>err
    seteval too many args here
EOF
is        $?        255        "Exit status"
file_is   out       "$NADA"    "Standard output"
file_is   err       "$STDERR"  "Standard error"
file_is   trap      "EXIT"     "Called exit"

##############################################################################

seteval GOT    "printf \"start\\\"'end\""
WANTED="start\"'end\No newline at end"
is "$GOT" "$WANTED" "Strip newline - String with quotes in"

seteval GOT    'printf "AA BB"'
WANTED="AA BB\No newline at end"
is "$GOT" "$WANTED" "Strip newline - String with space inside"

seteval GOT    'printf " AA "'
WANTED=" AA \No newline at end"
is "$GOT" "$WANTED" "Strip newline - String with space at start and end"

seteval GOT    'printf "\nAA\n"'
WANTED="
AA"
is "$GOT" "$WANTED" "Strip newline - String with newline at start and end"

##############################################################################

seteval GOT + "printf \"start\\\"'end\""
WANTED="start\"'end"
is "$GOT" "$WANTED" "Preserve newline - String with quotes in"

seteval GOT + 'printf "AA BB"'
WANTED="AA BB"
is "$GOT" "$WANTED" "Preserve newline - String with space inside"

seteval GOT + 'printf " AA "'
WANTED=" AA "
is "$GOT" "$WANTED" "Preserve newline - String with space at start and end"

seteval GOT + 'printf "\nAA\n"'
WANTED="
AA
"
is "$GOT" "$WANTED" "Preserve newline - String with newline at start and end"

##############################################################################

done_testing

#[eof]
