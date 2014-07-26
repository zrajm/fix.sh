#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"
NADA=""; strip_newline NADA                    # NADA = '\No newline at end'

dot() { stdin <"$1"; echo .; }
cat() { stdin <"$1"; }

##############################################################################

function_exists     seteval    "Function 'seteval' exists"

##############################################################################

cd "$(mktemp -d)"
title "seteval: Fail when more than two args are used without '+'"
STDERR="seteval: Bad number of args"
(
    trap 'echo EXIT >trap' 0
    seteval TOO MANY ARGS >out 2>err <&-
    trap - 0
    echo FULL >trap
)
is  $?             255        "Exit status"
is  "$(cat err)"   "$STDERR"  "Standard error"
is  "$(dot out)"   "."        "Standard output"
is  "$(cat trap)"  "EXIT"     "Called exit"

##############################################################################

cd "$(mktemp -d)"
title "seteval: Fail when more than three args are used"
STDERR="seteval: Bad number of args"
(
    trap 'echo EXIT >trap' 0
    seteval '+' TOO MANY ARGS >out 2>err <&-
    trap - 0
    echo FULL >trap
)
is  $?             255        "Exit status"
is  "$(cat err)"   "$STDERR"  "Standard error"
is  "$(dot out)"   "."        "Standard output"
is  "$(cat trap)"  "EXIT"     "Called exit"

##############################################################################

cd "$(mktemp -d)"
title "seteval: Fail when called with no args"
STDERR="seteval: Bad number of args"
(
    trap 'echo EXIT >trap' 0
    seteval >out 2>err <&-
    trap - 0
    echo FULL >trap
)
is  $?             255        "Exit status"
is  "$(cat err)"   "$STDERR"  "Standard error"
is  "$(dot out)"   "."        "Standard output"
is  "$(cat trap)"  "EXIT"     "Called exit"

##############################################################################

cd "$(mktemp -d)"
title "seteval: Fail when called with bad variable name"
STDERR="seteval: Bad VARNAME '_'"
(
    trap 'echo EXIT >trap' 0
    seteval _ >out 2>err <&-
    trap - 0
    echo FULL >trap
)
is  $?             255        "Exit status"
is  "$(cat err)"   "$STDERR"  "Standard error"
is  "$(dot out)"   "."        "Standard output"
is  "$(cat trap)"  "EXIT"     "Called exit"

##############################################################################

cd "$(mktemp -d)"
title "seteval: Ignore STDIN when two args are used"
VALUE="ARG\No newline at end."
(
    trap 'echo EXIT >trap' 0
    seteval XX "printf '%s' ARG" >out 2>err <<-"EOF"
	printf '%s' STDIN
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
title "seteval: Ignore STDIN when two args are used + don't strip newline"
VALUE="ARG."
(
    trap 'echo EXIT >trap' 0
    seteval + XX "printf '%s' ARG" >out 2>err <<-"EOF"
	printf '%s' STDIN
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
title "seteval: Process STDIN when one arg is used (ending in newline)"
VALUE="STDIN."
(
    trap 'echo EXIT >trap' 0
    seteval XX >out 2>err <<-"EOF"
	echo STDIN
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
title "seteval: Process STDIN when one arg is used (not ending in newline)"
VALUE="STDIN\No newline at end."
(
    trap 'echo EXIT >trap' 0
    seteval XX >out 2>err <<-"EOF"
	printf '%s' STDIN
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
title "seteval: Process STDIN when one arg is used + don't strip newline"
VALUE="STDIN
."
(
    trap 'echo EXIT >trap' 0
    seteval + XX >out 2>err <<-"EOF"
	echo STDIN
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
title "seteval: Process STDIN when one arg is used + no input"
VALUE="."
(
    trap 'echo EXIT >trap' 0
    seteval + XX >out 2>err
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
title "seteval: Overwriting previously set variable"
VALUE="NEW."
(
    trap 'echo EXIT >trap' 0
    X="OLD"
    seteval XX "echo NEW" >out 2>err
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
title "seteval: Process STDIN with space and quotes"
VALUE="  '  \"  ."
(
    trap 'echo EXIT >trap' 0
    seteval XX >out 2>err <<-"EOF"
	echo "  '  \"  "
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
title "seteval: Process arg with space and quotes"
VALUE="  '  \"  ."
(
    trap 'echo EXIT >trap' 0
    seteval XX "echo \"  '  \\\"  \"" >out 2>err
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

cd "$(mktemp -d)"
title "seteval: Two newlines at end, one should be stripped"
VALUE="x
."
(
    trap 'echo EXIT >trap' 0
    seteval XX "echo x; echo" >out 2>err
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


cd "$(mktemp -d)"
title "seteval: Two newlines at end, none stripped"
VALUE="x

."
(
    trap 'echo EXIT >trap' 0
    seteval + XX "echo x; echo" >out 2>err
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
