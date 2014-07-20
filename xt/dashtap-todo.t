#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"

is "$(type TODO)"     "TODO is a shell function"     "Function 'TODO' exists"
is "$(type END_TODO)" "END_TODO is a shell function" "Function 'END_TODO' exists"

##############################################################################

cd "$(mktemp -d)"
STDOUT="not ok 1 - descr # TODO with reason"
note <<-EOF
	Test description + TODO with reason in description.
	EOF

execute <<EOF trap >out 2>err
    TEST_COUNT=0
    is 1 2 'descr # TODO with reason'
EOF
is        $?        0          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       ""         "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
STDOUT="not ok 1 - descr # TODO"
note <<-EOF
	Test description + TODO without reason in description.
	EOF

execute <<EOF trap >out 2>err
    TEST_COUNT=0
    is 1 2 'descr # TODO'
EOF
is        $?        0          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       ""         "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
STDOUT="not ok 1 # TODO with reason"
note <<-EOF
	No test description + TODO with reason in description.
	EOF

execute <<EOF trap >out 2>err
    TEST_COUNT=0
    is 1 2 '# TODO with reason'
EOF
is        $?        0          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       ""         "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
STDOUT="not ok 1 # TODO"
note <<-EOF
	No test description + TODO without reason in description.
	EOF

execute <<EOF trap >out 2>err
    TEST_COUNT=0
    is 1 2 '# TODO'
EOF
is        $?        0          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       ""         "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
STDOUT="not ok 1 - descr # TODO with reason"
note <<-EOF
	Test description + TODO with reason as separate function.
	EOF

execute <<EOF trap >out 2>err
    TEST_COUNT=0
    TODO "with reason"
    is 1 2 'descr'
EOF
is        $?        0          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       ""         "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
STDOUT="not ok 1 - descr # TODO"
note <<-EOF
	Test description + TODO without reason as separate function.
	EOF

execute <<EOF trap >out 2>err
    TEST_COUNT=0
    TODO
    is 1 2 'descr'
EOF
is        $?        0          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       ""         "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
STDOUT="not ok 1 # TODO with reason"
note <<-EOF
	No test description + TODO with reason as separate function.
	EOF

execute <<EOF trap >out 2>err
    TEST_COUNT=0
    TODO "with reason"
    is 1 2
EOF
is        $?        0          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       ""         "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
STDOUT="not ok 1 # TODO"
note <<-EOF
	No test description + TODO without reason as separate function.
	EOF

execute <<EOF trap >out 2>err
    TEST_COUNT=0
    TODO
    is 1 2
EOF
is        $?        0          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       ""         "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
STDOUT="not ok 1 - descr"
STDERR="
#   Failed test 'descr'
#   in 'xt/dashtap-todo.t'
#     GOT   : 1
#     WANTED: 2"
note <<-EOF
	Test description + no TODO.
	EOF

execute <<EOF trap >out 2>err
    TEST_COUNT=0
    TODO
    END_TODO
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
#   Failed test in 'xt/dashtap-todo.t'
#     GOT   : 1
#     WANTED: 2"
note <<-EOF
	No test description + no TODO.
	EOF

execute <<EOF trap >out 2>err
    TEST_COUNT=0
    TODO
    END_TODO
    is 1 2
EOF
is        $?        1          "Exit status"
file_is   out       "$STDOUT"  "Standard output"
file_is   err       "$STDERR"  "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

done_testing

#[eof]