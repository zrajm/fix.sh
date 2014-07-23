#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"

dot() { stdin <"$1"; echo .; }
cat() { stdin <"$1"; }

##############################################################################

function_exists  title      "Function 'title' exists"

##############################################################################

cd "$(mktemp -d)"
title "title: Fail when called with two args"
STDOUT=""
STDERR="title: Bad number of args
"
(
    dashtap_init
    trap 'echo EXIT >trap' 0
    title MANY ARGS
    fail "Test description"
    trap - 0
    echo FULL >trap
) >out 2>err
is  $?             255         "Exit status"
is  "$(dot err)"   "$STDERR."  "Standard error"
is  "$(dot out)"   "$STDOUT."  "Standard output"
is  "$(cat trap)"  "EXIT"      "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "title: Fail when called with no args"
STDOUT=""
STDERR="title: Bad number of args
"
(
    dashtap_init
    trap 'echo EXIT >trap' 0
    title
    fail "Test description"
    trap - 0
    echo FULL >trap
) >out 2>err
is  $?             255         "Exit status"
is  "$(dot err)"   "$STDERR."  "Standard error"
is  "$(dot out)"   "$STDOUT."  "Standard output"
is  "$(cat trap)"  "EXIT"      "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "title: Setting a title"
STDOUT="# Test title
not ok 1 - Test description
"
STDERR="
#   Test title
#   Failed test 'Test description'
#   in 'xt/dashtap-title.t'
"
(
    dashtap_init
    trap 'echo EXIT >trap' 0
    title "Test title"
    fail "Test description"
    trap - 0
    echo FULL >trap
) >out 2>err
is  $?             0           "Exit status"
is  "$(dot err)"   "$STDERR."  "Standard error"
is  "$(dot out)"   "$STDOUT."  "Standard output"
is  "$(cat trap)"  "FULL"      "Didn't call exit"

##############################################################################

done_testing

#[eof]
