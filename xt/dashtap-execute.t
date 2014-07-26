#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
NADA=""; strip_newline NADA                    # NADA = '\No newline at end'

##############################################################################

function_exists     execute    "Function 'execute' exists"

##############################################################################

cd "$(mktemp -d)"
title "execute: Fail when more than two args are used"
STDERR="execute: Bad number of args"
(
    trap 'echo EXIT >trap' 0
    execute TOO MANY ARGS >out 2>err
    trap - 0
    echo FULL >trap
)
is        $?        255          "Exit status"
file_is   out       "$NADA"      "Standard output"
file_is   err       "$STDERR"    "Standard error"
file_is   trap      "EXIT"       "Called exit"

##############################################################################

cd "$(mktemp -d)"
title "execute: Fail when called with no args"
STDERR="execute: Bad number of args"
(
    trap 'echo EXIT >trap' 0
    execute >out 2>err
    trap - 0
    echo FULL >trap
)
is        $?        255        "Exit status"
file_is   out       "$NADA"    "Standard output"
file_is   err       "$STDERR"  "Standard error"
file_is   trap      "EXIT"     "Called exit"

##############################################################################

cd "$(mktemp -d)"
title "execute: Ignore STDIN when two args are used"
(
    execute 'echo ARG' trap >out 2>err <<-"EOF"
	echo STDIN
	EOF
)
is        $?        0          "Exit status"
file_is   out       "ARG"      "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "execute: Process STDIN when one arg is used"
(
    execute trap >out 2>err <<-"EOF"
	echo STDIN
	EOF
)
is        $?        0          "Exit status"
file_is   out       "STDIN"    "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "execute: Returning false"
(
    execute trap >out 2>err <<-"EOF"
	! :
	EOF
)
is        $?        1          "Exit status"
file_is   out       "$NADA"    "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "execute: Exiting with true exit status"
(
    execute trap >out 2>err <<-"EOF"
	exit 0
	EOF
)
is        $?        0          "Exit status"
file_is   out       "$NADA"    "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "EXIT"     "Called exit"

##############################################################################

cd "$(mktemp -d)"
title "execute: Exiting with false exit status"
(
    execute trap >out 2>err <<-"EOF"
	exit 1
	EOF
)
is        $?        1          "Exit status"
file_is   out       "$NADA"    "Standard output"
file_is   err       "$NADA"    "Standard error"
file_is   trap      "EXIT"     "Called exit"

##############################################################################

done_testing

#[eof]
