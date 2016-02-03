#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
NADA=""; strip_newline NADA                    # NADA = '\No newline at end'

##############################################################################

function_exists         match        "Function 'match' exists"

##############################################################################

cd "$(mktemp -d)"
title "match: Fail when more than two args are used"
STDERR="match: Bad number of args"
execute 3<<"EOF" trapout >stdout 2>stderr
    match TOO MANY ARGS
EOF
is           $?         255          "Exit status"
file_is      stdout     "$NADA"      "Standard output"
file_is      stderr     "$STDERR"    "Standard error"
file_is      trapout    "EXIT"       "Called exit"

##############################################################################

cd "$(mktemp -d)"
title "match: Fail when called with no args"
STDERR="match: Bad number of args"
execute 3<<"EOF" trapout >stdout 2>stderr
    match
EOF
is           $?         255          "Exit status"
file_is      stdout     "$NADA"      "Standard output"
file_is      stderr     "$STDERR"    "Standard error"
file_is      trapout    "EXIT"       "Called exit"

##############################################################################

cd "$(mktemp -d)"
title "match: Ignore STDIN when two args are used"
execute 3<<"EOF" trapout >stdout 2>stderr
    echo "STDIN" | match "ARG" "ARG"
EOF
is           $?         0            "Exit status"
file_is      stdout     "$NADA"      "Standard output"
file_is      stderr     "$NADA"      "Standard error"
file_is      trapout    "FULL"       "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "match: Process STDIN when one arg is used"
execute 3<<"EOF" trapout >stdout 2>stderr
    echo "STDIN" | match "STDIN"
EOF
is           $?         0            "Exit status"
file_is      stdout     "$NADA"      "Standard output"
file_is      stderr     "$NADA"      "Standard error"
file_is      trapout    "FULL"       "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "match: Fail to find '*' when missing in string"
execute 3<<"EOF" trapout >stdout 2>stderr
    match "*" "ABC"
EOF
is           $?         1            "Exit status without match"
file_is      stdout     "$NADA"      "Standard output"
file_is      stderr     "$NADA"      "Standard error"
file_is      trapout    "FULL"       "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "match: Find '*' last in string"
execute 3<<"EOF" trapout >stdout 2>stderr
    match "*" "AB*"
EOF
is           $?         0            "Exit status"
file_is      stdout     "$NADA"      "Standard output"
file_is      stderr     "$NADA"      "Standard error"
file_is      trapout    "FULL"       "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "match: Find '*' in middle of string"
execute 3<<"EOF" trapout >stdout 2>stderr
    match "*" "A*C"
EOF
is           $?         0            "Exit status"
file_is      stdout     "$NADA"      "Standard output"
file_is      stderr     "$NADA"      "Standard error"
file_is      trapout    "FULL"       "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "match: Find '*' at beginning of string"
execute 3<<"EOF" trapout >stdout 2>stderr
    match "*" "*BC"
EOF
is           $?         0            "Exit status"
file_is      stdout     "$NADA"      "Standard output"
file_is      stderr     "$NADA"      "Standard error"
file_is      trapout    "FULL"       "Didn't call exit"

##############################################################################

done_testing

#[eof]
