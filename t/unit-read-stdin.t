#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2016 zrajm <fix@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "dashtap/dashtap.sh"
title - <<"EOF"
Unit tests for read_stdin().
EOF

init_test

# import functions
for FUNC in read_stdin say die is_mother; do
    import_function "$FUNC" <"$TESTCMD"
done

################################################################################

title "01. Leading and trailing spaces should be preserved"
mkdir "01" && cd "01" && note "DIR: $PWD"

execute trap >stdout 2>stderr 3<<"EOF" 4>env1.txt 5>env2.txt; RC="$?"
    echo " LEADING + TRAILING SPACE " | read_stdin
EOF
STDOUT=" LEADING + TRAILING SPACE "
STDERR="$NADA"

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

title "02. No standard input should return false + error message"
mkdir "02" && cd "02" && note "DIR: $PWD"

execute trap >stdout 2>stderr 3<<"EOF" 4>env1.txt 5>env2.txt; RC="$?"
    read_stdin
EOF
STDOUT="$NADA"
STDERR="read_stdin: Missing input on stdin"

file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
is        "$RC"     1          "Exit status"
file_is   trap      "FULL"     "Shouldn't call exit"
is_same_env \
    "RC" \
    "Environment variable leakage" \
    3<env1.txt 4<env2.txt
cd ..

################################################################################

title "03. Missing newline at end of input should pass"
mkdir "03" && cd "03" && note "DIR: $PWD"

execute trap >stdout 2>stderr 3<<"EOF" 4>env1.txt 5>env2.txt; RC="$?"
    printf "%s" "WORD" | read_stdin
EOF
STDOUT="WORD"
STDERR="$NADA"

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

done_testing

#[eof]
