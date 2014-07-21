#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
NADA=""; strip_newline NADA                    # NADA = '\No newline at end'

is "$(type SKIP)"     "SKIP is a shell function"     "Function 'SKIP' exists"
is "$(type END_SKIP)" "END_SKIP is a shell function" "Function 'END_SKIP' exists"

##############################################################################

cd "$(mktemp -d)"
STDOUT="ok 1 - descr # SKIP with reason"
note <<-EOF
	Test description + SKIP with reason in description.
	EOF

execute <<EOF trap >out 2>err
    TEST_COUNT=0
    is 1 2 'descr # SKIP with reason'
EOF
is        $?        0          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
STDOUT="ok 1 - descr # SKIP"
note <<-EOF
	Test description + SKIP without reason in description.
	EOF

execute <<EOF trap >out 2>err
    TEST_COUNT=0
    is 1 2 'descr # SKIP'
EOF
is        $?        0          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
STDOUT="ok 1 # SKIP with reason"
note <<-EOF
	No test description + SKIP with reason in description.
	EOF

execute <<EOF trap >out 2>err
    TEST_COUNT=0
    is 1 2 '# SKIP with reason'
EOF
is        $?        0          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
STDOUT="ok 1 # SKIP"
note <<-EOF
	No test description + SKIP without reason in description.
	EOF

execute <<EOF trap >out 2>err
    TEST_COUNT=0
    is 1 2 '# SKIP'
EOF
is        $?        0          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
STDOUT="ok 1 - descr # SKIP with reason"
note <<-EOF
	Test description + SKIP with reason as separate function.
	EOF

execute <<EOF trap >out 2>err
    TEST_COUNT=0
    SKIP "with reason"
    is 1 2 'descr'
EOF
is        $?        0          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
STDOUT="ok 1 - descr # SKIP"
note <<-EOF
	Test description + SKIP without reason as separate function.
	EOF

execute <<EOF trap >out 2>err
    TEST_COUNT=0
    SKIP
    is 1 2 'descr'
EOF
is        $?        0          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
STDOUT="ok 1 # SKIP with reason"
note <<-EOF
	No test description + SKIP with reason as separate function.
	EOF

execute <<EOF trap >out 2>err
    TEST_COUNT=0
    SKIP "with reason"
    is 1 2
EOF
is        $?        0          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
STDOUT="ok 1 # SKIP"
note <<-EOF
	No test description + SKIP without reason as separate function.
	EOF

execute <<EOF trap >out 2>err
    TEST_COUNT=0
    SKIP
    is 1 2
EOF
is        $?        0          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
STDOUT="not ok 1 - descr"
STDERR="
#   Failed test 'descr'
#   in 'xt/dashtap-skip.t'
#     GOT   : 1
#     WANTED: 2"
note <<-EOF
	Test description + no SKIP.
	EOF

execute <<EOF trap >out 2>err
    TEST_COUNT=0
    SKIP
    END_SKIP
    unset BAIL_ON_FAIL DIE_ON_FAIL
    is 1 2 "descr"
EOF
is        $?        1          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       "$STDERR"  "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
STDOUT="not ok 1"
STDERR="
#   Failed test in 'xt/dashtap-skip.t'
#     GOT   : 1
#     WANTED: 2"
note <<-EOF
	No test description + no SKIP.
	EOF

execute <<EOF trap >out 2>err
    TEST_COUNT=0
    SKIP
    END_SKIP
    unset BAIL_ON_FAIL DIE_ON_FAIL
    is 1 2
EOF
is        $?        1          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       "$STDERR"  "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

done_testing

#[eof]
