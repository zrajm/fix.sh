#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
NADA=""; strip_newline NADA                    # NADA = '\No newline at end'

dot() { stdin <"$1"; echo .; }
cat() { stdin <"$1"; }

##############################################################################

function_exists     setread    "Function 'setread' exists"

##############################################################################

cd "$(mktemp -d)"
title "setread: Fail when more than two args are used without '+'"
STDERR="setread: Bad number of args"
(
    trap 'echo EXIT >trap' 0
    setread TOO MANY ARGS >out 2>err <&-
    trap - 0
    echo FULL >trap
)
is  $?             255        "Exit status"
is  "$(cat err)"   "$STDERR"  "Standard error"
is  "$(dot out)"   "."        "Standard output"
is  "$(cat trap)"  "EXIT"     "Called exit"

##############################################################################

cd "$(mktemp -d)"
title "setread: Fail when more than three args are used"
STDERR="setread: Bad number of args"
(
    trap 'echo EXIT >trap' 0
    setread '+' TOO MANY ARGS >out 2>err <&-
    trap - 0
    echo FULL >trap
)
is  $?             255        "Exit status"
is  "$(cat err)"   "$STDERR"  "Standard error"
is  "$(dot out)"   "."        "Standard output"
is  "$(cat trap)"  "EXIT"     "Called exit"

##############################################################################

cd "$(mktemp -d)"
title "setread: Fail when called with no args"
STDERR="setread: Bad number of args"
(
    trap 'echo EXIT >trap' 0
    setread >out 2>err <&-
    trap - 0
    echo FULL >trap
)
is  $?             255        "Exit status"
is  "$(cat err)"   "$STDERR"  "Standard error"
is  "$(dot out)"   "."        "Standard output"
is  "$(cat trap)"  "EXIT"     "Called exit"

##############################################################################

cd "$(mktemp -d)"
title "setread: Fail when called with bad variable name"
STDERR="setread: Bad VARNAME '_'"
(
    trap 'echo EXIT >trap' 0
    setread _ >out 2>err <&-
    trap - 0
    echo FULL >trap
)
is  $?             255        "Exit status"
is  "$(cat err)"   "$STDERR"  "Standard error"
is  "$(dot out)"   "."        "Standard output"
is  "$(cat trap)"  "EXIT"     "Called exit"

##############################################################################

cd "$(mktemp -d)"
title "setread: Ignore STDIN when two args are used"
VALUE="ARG\No newline at end."
(
    trap 'echo EXIT >trap' 0
    setread XX "ARG" >out 2>err <<-"EOF"
	STDIN
	EOF
    printf "%s" "$XX" >value
    trap - 0
    echo FULL >trap
)
is  $?             0          "Exit status"
is  "$(cat err)"   ""         "Standard error"
is  "$(dot out)"   "."        "Standard output"
is  "$(dot value)" "$VALUE"   "Variable value"
is  "$(cat trap)"  "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "setread: Ignore STDIN when two args are used + don't strip newline"
VALUE="ARG."
(
    trap 'echo EXIT >trap' 0
    setread + XX "ARG" >out 2>err <<-"EOF"
	STDIN
	EOF
    printf "%s" "$XX" >value
    trap - 0
    echo FULL >trap
)
is  $?             0          "Exit status"
is  "$(cat err)"   ""         "Standard error"
is  "$(dot out)"   "."        "Standard output"
is  "$(dot value)" "$VALUE"   "Variable value"
is  "$(cat trap)"  "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "setread: Process STDIN when one arg is used"
VALUE="STDIN."
(
    trap 'echo EXIT >trap' 0
    setread XX >out 2>err <<-"EOF"
	STDIN
	EOF
    printf "%s" "$XX" >value
    trap - 0
    echo FULL >trap
)
is  $?             0          "Exit status"
is  "$(cat err)"   ""         "Standard error"
is  "$(dot out)"   "."        "Standard output"
is  "$(dot value)" "$VALUE"   "Variable value"
is  "$(cat trap)"  "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "setread: Process STDIN when one arg is used + don't strip newline"
VALUE="STDIN
."
(
    trap 'echo EXIT >trap' 0
    setread + XX >out 2>err <<-"EOF"
	STDIN
	EOF
    printf "%s" "$XX" >value
    trap - 0
    echo FULL >trap
)
is  $?             0          "Exit status"
is  "$(cat err)"   ""         "Standard error"
is  "$(dot out)"   "."        "Standard output"
is  "$(dot value)" "$VALUE"   "Variable value"
is  "$(cat trap)"  "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "setread: Process STDIN when one arg is used + no input"
VALUE="."
(
    trap 'echo EXIT >trap' 0
    setread + XX >out 2>err
    printf "%s" "$XX" >value
    trap - 0
    echo FULL >trap
)
is  $?             0          "Exit status"
is  "$(cat err)"   ""         "Standard error"
is  "$(dot out)"   "."        "Standard output"
is  "$(dot value)" "$VALUE"   "Variable value"
is  "$(cat trap)"  "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "setread: Overwriting previously set variable"
VALUE="NEW."
(
    trap 'echo EXIT >trap' 0
    X="STRING"
    setread + XX "NEW" >out 2>err
    printf "%s" "$XX" >value
    trap - 0
    echo FULL >trap
)
is  $?             0          "Exit status"
is  "$(cat err)"   ""         "Standard error"
is  "$(dot out)"   "."        "Standard output"
is  "$(dot value)" "$VALUE"   "Variable value"
is  "$(cat trap)"  "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "setread: Process STDIN with space and quotes"
VALUE="  '  \"  ."
(
    trap 'echo EXIT >trap' 0
    setread XX >out 2>err <<-"EOF"
	  '  "  
	EOF
    printf "%s" "$XX" >value
    trap - 0
    echo FULL >trap
)
is  $?             0          "Exit status"
is  "$(cat err)"   ""         "Standard error"
is  "$(dot out)"   "."        "Standard output"
is  "$(dot value)" "$VALUE"   "Variable value"
is  "$(cat trap)"  "FULL"     "Didn't call exit"

##############################################################################

cd "$(mktemp -d)"
title "setread: Process arg with space and quotes"
VALUE="  '  \"  \No newline at end."
(
    trap 'echo EXIT >trap' 0
    setread XX "  '  \"  " >out 2>err
    printf "%s" "$XX" >value
    trap - 0
    echo FULL >trap
)
is  $?             0        "Exit status"
is  "$(cat err)"   ""       "Standard error"
is  "$(dot out)"   "."      "Standard output"
is  "$(dot value)" "$VALUE" "Variable value"
is  "$(cat trap)"  "FULL"   "Didn't call exit"

##############################################################################

done_testing

#[eof]
