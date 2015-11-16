#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
NADA=""; strip_newline NADA                    # NADA = '\No newline at end'

##############################################################################

function_exists strip_newline  "Function 'strip_newline' exists"

##############################################################################

cd "$(mktemp -d)"
STDERR="strip_newline: Bad number of args"
title "strip_newline: Fail when two or more args are used"
execute <<"EOF" trap >out 2>err
    LINE=""
    strip_newline MANY ARGS
    echo "$LINE"
EOF
is        $?        255        "Exit status"
file_is   out       "$NADA"    "Standard output"
file_is   err       "$STDERR"  "Standard error"
file_is   trap      "EXIT"     "Called exit"

##############################################################################

cd "$(mktemp -d)"
STDERR="strip_newline: Bad VARNAME 'BAD-VAR'"
title "strip_newline: Fail when bad variable name is used"
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
title "strip_newline: Zero length string"
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
title "strip_newline: String with no newline at end"
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
title "strip_newline: String leading + trailing spaces"
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
title "strip_newline: String ending in newline"
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

cd "$(mktemp -d)"
STDOUT="Hello
"
title "strip_newline: with string ending in two newlines"
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
