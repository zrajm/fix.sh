#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2016 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
NONL=""; strip_newline NONL                    # NONL = '\No newline at end'

##############################################################################

function_exists  stdin      "Function 'stdin' exists"
cd "$(mktemp -d)" && note "DIR: $PWD"

##############################################################################

title "01. Leading and trailing spaces should be preserved"
mkdir "01" && cd "01" && note "DIR: $PWD"

execute trap >stdout 2>stderr 3<<"EOF" 4>env1.txt 5>env2.txt; RC="$?"
    echo " LEADING + TRAILING SPACE " | stdin
EOF
STDOUT=" LEADING + TRAILING SPACE "
STDERR="$NONL"

file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
is        "$RC"     0          "Exit status"
file_is   trap      "FULL"     "Shouldn't call exit"
is_same_env \
    "RC" \
    "Environment variable leakage" \
    3<env1.txt 4<env2.txt
cd ..

################################################################################

title "02. No standard input should output nothing"
mkdir "02" && cd "02" && note "DIR: $PWD"

execute trap >stdout 2>stderr 3<<"EOF"; RC="$?"
    stdin
EOF
STDOUT="$NONL"
STDERR="$NONL"

file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
is        "$RC"     0          "Exit status"
file_is   trap      "FULL"     "Shouldn't call exit"
# Skipping the 'is_same_env' tests here.

################################################################################

title "03. Missing newline at end should be retained in output"
mkdir "03" && cd "03" && note "DIR: $PWD"

execute trap >stdout 2>stderr 3<<"EOF"; RC="$?"
    printf "%s" "WORD" | stdin
EOF
STDOUT="WORD$NONL"
STDERR="$NONL"

file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
is        "$RC"     0          "Exit status"
file_is   trap      "FULL"     "Shouldn't call exit"
# Skipping the 'is_same_env' tests here.

################################################################################

done_testing

#[eof]
