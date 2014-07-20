#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"

is "$(type varname)"  "varname is a shell function"  "Function 'varname' exists"

##############################################################################

cd "$(mktemp -d)"
note "Zero character long variable name"
execute <<EOF trap >out 2>err
    varname ""
EOF
is        $?        1          "Exit status"
file_is   out       ""         "Standard output"
file_is   err       ""         "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
note "Variable name with one letter"
execute <<EOF trap >out 2>err
    varname A
EOF
is        $?        0          "Exit status"
file_is   out       ""         "Standard output"
file_is   err       ""         "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
note "Variable name with leading digit"
execute <<EOF trap >out 2>err
    varname 123abc
EOF
is        $?        1          "Exit status"
file_is   out       ""         "Standard output"
file_is   err       ""         "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
note "Variable name consisting of single underscore"
execute <<EOF trap >out 2>err
    varname _
EOF
is        $?        1          "Exit status"
file_is   out       ""         "Standard output"
file_is   err       ""         "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
note "Variable name with leading underscore"
execute <<EOF trap >out 2>err
    varname _SOME_NAME
EOF
is        $?        0          "Exit status"
file_is   out       ""         "Standard output"
file_is   err       ""         "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
note "Variable name with all allowed characters"
execute <<EOF trap >out 2>err
    varname abcdefghijklmnopqrstuvwxyz_ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789
EOF
is        $?        0          "Exit status"
file_is   out       ""         "Standard output"
file_is   err       ""         "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

done_testing

#[eof]