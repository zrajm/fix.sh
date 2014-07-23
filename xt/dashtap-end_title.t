#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"

dot() { stdin <"$1"; echo .; }
cat() { stdin <"$1"; }

##############################################################################

function_exists  title      "Function 'title' exists"
function_exists  end_title  "Function 'end_title' exists"

##############################################################################

cd "$(mktemp -d)"
title "end_title: Fail when called with one arg"
STDOUT="# Test title
not ok 1 - Test description
"
STDERR="
#   Failed test 'Test description'
#   in 'xt/dashtap-end_title.t'
"
(
    dashtap_init
    trap 'echo EXIT >trap' 0
    title "Test title"
    end_title
    fail "Test description"
    trap - 0
    echo FULL >trap
) >out 2>err
is  $?             0           "Exit status"
is  "$(dot err)"   "$STDERR."  "Standard error"
is  "$(dot out)"   "$STDOUT."  "Standard output"
is  "$(cat trap)"  "FULL"      "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "end_title: Unsetting the title"
STDOUT="# Test title
not ok 1 - Test description
"
STDERR="
#   Failed test 'Test description'
#   in 'xt/dashtap-end_title.t'
"
(
    dashtap_init
    trap 'echo EXIT >trap' 0
    title "Test title"
    end_title
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
