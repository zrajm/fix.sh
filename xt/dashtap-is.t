#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"

dot() { stdin <"$1"; echo .; }
cat() { stdin <"$1"; }

##############################################################################

function_exists     is      "Function 'is' exists"

##############################################################################

cd "$(mktemp -d)"
title "is: Fail when called with one (or fewer) args"
STDOUT=""
STDERR="is: Bad number of args
"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >trap' 0
    is 1
    STATUS=$?
    trap - 0
    echo FULL >trap
    exit $STATUS
) >out 2>err
is  $?             255         "Exit status"
is  "$(dot err)"   "$STDERR."  "Standard error"
is  "$(dot out)"   "$STDOUT."  "Standard output"
is  "$(cat trap)"  "EXIT"      "Called exit"

##############################################################################

cd "$(mktemp -d)"
title "is: Fail when called with four (or more) args"
STDOUT=""
STDERR="is: Bad number of args
"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >trap' 0
    is FAR TOO MANY ARGS
    STATUS=$?
    trap - 0
    echo FULL >trap
    exit $STATUS
) >out 2>err
is  $?             255         "Exit status"
is  "$(dot err)"   "$STDERR."  "Standard error"
is  "$(dot out)"   "$STDOUT."  "Standard output"
is  "$(cat trap)"  "EXIT"      "Called exit"

##############################################################################

# FIXME: Check with 'TODO' in description
# FIXME: Check with 'SKIP' in description
# FIXME: Check with 'TODO' called separately
# FIXME: Check with 'SKIP' called separately

##############################################################################

cd "$(mktemp -d)"
title "is: Fail when called with two differing args"
STDOUT="not ok 1
"
STDERR="
#   Failed test in 'xt/dashtap-is.t'
#     GOT   : 1
#     WANTED: 2
"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >trap' 0
    is 1 2
    STATUS=$?
    trap - 0
    echo FULL >trap
    exit $STATUS
) >out 2>err
is  $?             1           "Exit status"
is  "$(dot err)"   "$STDERR."  "Standard error"
is  "$(dot out)"   "$STDOUT."  "Standard output"
is  "$(cat trap)"  "FULL"      "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "is: Fail when called with two differing args + description"
STDOUT="not ok 1 - Description
"
STDERR="
#   Failed test 'Description'
#   in 'xt/dashtap-is.t'
#     GOT   : 1
#     WANTED: 2
"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >trap' 0
    is 1 2 Description
    STATUS=$?
    trap - 0
    echo FULL >trap
    exit $STATUS
) >out 2>err
is  $?             1           "Exit status"
is  "$(dot err)"   "$STDERR."  "Standard error"
is  "$(dot out)"   "$STDOUT."  "Standard output"
is  "$(cat trap)"  "FULL"      "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "is: Pass when called with two equal args"
STDOUT="ok 1
"
STDERR=""
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >trap' 0
    is 1 1
    STATUS=$?
    trap - 0
    echo FULL >trap
    exit $STATUS
) >out 2>err
is  $?             0           "Exit status"
is  "$(dot err)"   "$STDERR."  "Standard error"
is  "$(dot out)"   "$STDOUT."  "Standard output"
is  "$(cat trap)"  "FULL"      "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "is: Pass when called with two equal args + description"
STDOUT="ok 1 - Description
"
STDERR=""
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >trap' 0
    is 1 1 Description
    STATUS=$?
    trap - 0
    echo FULL >trap
    exit $STATUS
) >out 2>err
is  $?             0           "Exit status"
is  "$(dot err)"   "$STDERR."  "Standard error"
is  "$(dot out)"   "$STDOUT."  "Standard output"
is  "$(cat trap)"  "FULL"      "Didn't call exit"

##############################################################################




##############################################################################

done_testing

#[eof]
