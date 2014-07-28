#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"

dot() { stdin <"$1"; echo .; }
cat() { stdin <"$1"; }

##############################################################################

function_exists  END_SKIP  "Function 'END_SKIP' exists"

##############################################################################

cd "$(mktemp -d)"
title "END_SKIP: Fail when called with one (or more) args"
STDOUT=""
STDERR="END_SKIP: No args allowed
"
(
    dashtap_init
    trap 'echo EXIT >trap' 0
    SKIP "Reason"
    END_SKIP ARG
    trap - 0
    echo FULL >trap
) >out 2>err
is  $?             255         "Exit status"
is  "$(dot err)"   "$STDERR."  "Standard error"
is  "$(dot out)"   "$STDOUT."  "Standard output"
is  "$(cat trap)"  "EXIT"      "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "END_SKIP: Fail when called without first using SKIP"
STDOUT=""
STDERR="END_SKIP: SKIP not set
"
(
    dashtap_init
    trap 'echo EXIT >trap' 0
    END_SKIP
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
title "END_SKIP: Unsetting the SKIP"
STDOUT="ok 1 - pass # SKIP Reason
ok 2 - fail # SKIP Reason
ok 3 - is # SKIP Reason
ok 4 - pass
not ok 5 - fail
not ok 6 - is
"
STDERR="
#   Failed test 'fail'
#   in 'xt/dashtap-end_skip.t'
#   Failed test 'is'
#   in 'xt/dashtap-end_skip.t'
#     GOT   : 1
#     WANTED: 2
"
(
    dashtap_init
    trap 'echo EXIT >trap' 0
    SKIP "Reason"
    pass "pass"
    fail "fail"
    is 1 2 "is"
    END_SKIP
    pass "pass"
    fail "fail"
    is 1 2 "is"
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
