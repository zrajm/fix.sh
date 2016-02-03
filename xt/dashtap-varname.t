#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
NADA=""; strip_newline NADA                    # NADA = '\No newline at end'

##############################################################################

function_exists     varname    "Function 'varname' exists"

##############################################################################

cd "$(mktemp -d)"
title "varname: Zero character long variable name"
execute 3<<"EOF" trap >out 2>err
    varname ""
EOF
is        $?        1          "Exit status"
file_is   out       "$NADA"    "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "varname: Variable name with one letter"
execute 3<<"EOF" trap >out 2>err
    varname A
EOF
is        $?        0          "Exit status"
file_is   out       "$NADA"    "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "varname: Variable name with leading digit"
execute 3<<"EOF" trap >out 2>err
    varname 123abc
EOF
is        $?        1          "Exit status"
file_is   out       "$NADA"    "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "varname: Variable name consisting of single underscore"
execute 3<<"EOF" trap >out 2>err
    varname _
EOF
is        $?        1          "Exit status"
file_is   out       "$NADA"    "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "varname: Variable name with leading underscore"
execute 3<<"EOF" trap >out 2>err
    varname _SOME_NAME
EOF
is        $?        0          "Exit status"
file_is   out       "$NADA"    "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "varname: Variable name with all allowed characters"
execute 3<<"EOF" trap >out 2>err
    varname abcdefghijklmnopqrstuvwxyz_ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789
EOF
is        $?        0          "Exit status"
file_is   out       "$NADA"    "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

done_testing

#[eof]
