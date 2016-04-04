#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2016 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
NADA=""; strip_newline NADA                    # NADA = '\No newline at end'
prefix "is_same_env"

############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "Pass when called with two identical environments"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >&3' 0
    is_same_env : "Description" 3<<-"=" 4<<-"-"; RC="$?"
	X=hello1
	Y=hello2
	=
	X=hello1
	Y=hello2
	-
    trap - 0
    echo FULL >&3
    exit "$RC"
) >stdout 2>stderr 3>trap; RC="$?"

STDOUT="ok 1 - Description"
STDERR="$NADA"

is              "$RC"              0             "Exit status"
file_is         stdout             "$STDOUT"     "Standard output"
file_is         stderr             "$STDERR"     "Standard error"
file_is         trap               "FULL"        "Trap status"

############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "Fail when called with one variable changed"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >&3' 0
    is_same_env : "Description" 3<<-"=" 4<<-"-"; RC="$?"
	X=hello1
	Y=first
	Y2=first
	Z=hello3
	=
	X=hello1
	Y=thereafter
	Y2=thereafter
	Z=hello3
	-
    trap - 0
    echo FULL >&3
    exit "$RC"
) >stdout 2>stderr 3>trap; RC="$?"

STDOUT="not ok 1 - Description"
STDERR="
#   Failed test 'Description'
#   in 'xt/dashtap-is_same_env.t'
#     Variable value(s) changed:
#     Y=first --> thereafter
#     Y2=first --> thereafter"

is              "$RC"              1             "Exit status"
file_is         stdout             "$STDOUT"     "Standard output"
file_is         stderr             "$STDERR"     "Standard error"
file_is         trap               "FULL"        "Trap status"

############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "Pass when called with one ignored variable changed"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >&3' 0
    is_same_env Y "Description" 3<<-"=" 4<<-"-"; RC="$?"
	X=hello1
	Y=first
	Z=hello3
	=
	X=hello1
	Y=thereafter
	Z=hello3
	-
    trap - 0
    echo FULL >&3
    exit "$RC"
) >stdout 2>stderr 3>trap; RC="$?"

STDOUT="ok 1 - Description"
STDERR="$NADA"

is              "$RC"              0             "Exit status"
file_is         stdout             "$STDOUT"     "Standard output"
file_is         stderr             "$STDERR"     "Standard error"
file_is         trap               "FULL"        "Trap status"

############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "Fail when called with one variable added"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >&3' 0
    is_same_env : "Description" 3<<-"=" 4<<-"-"; RC="$?"
	X=hello1
	Z=hello3
	=
	X=hello1
	Y=added
	Z=hello3
	-
    trap - 0
    echo FULL >&3
    exit "$RC"
) >stdout 2>stderr 3>trap; RC="$?"

STDOUT="not ok 1 - Description"
STDERR="
#   Failed test 'Description'
#   in 'xt/dashtap-is_same_env.t'
#     Variable(s) created:
#     Y=added"

is              "$RC"              1             "Exit status"
file_is         stdout             "$STDOUT"     "Standard output"
file_is         stderr             "$STDERR"     "Standard error"
file_is         trap               "FULL"        "Trap status"

############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "Pass when called with one ignored variable added"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >&3' 0
    is_same_env Y "Description" 3<<-"=" 4<<-"-"; RC="$?"
	X=hello1
	Z=hello3
	=
	X=hello1
	Y=added
	Z=hello3
	-
    trap - 0
    echo FULL >&3
    exit "$RC"
) >stdout 2>stderr 3>trap; RC="$?"

STDOUT="ok 1 - Description"
STDERR="$NADA"

is              "$RC"              0             "Exit status"
file_is         stdout             "$STDOUT"     "Standard output"
file_is         stderr             "$STDERR"     "Standard error"
file_is         trap               "FULL"        "Trap status"

############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "Fail when called with two variables added at end"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >&3' 0
    is_same_env : "Description" 3<<-"=" 4<<-"-"; RC="$?"
	X=hello1
	=
	X=hello1
	Y=added
	Z=added
	-
    trap - 0
    echo FULL >&3
    exit "$RC"
) >stdout 2>stderr 3>trap; RC="$?"

STDOUT="not ok 1 - Description"
STDERR="
#   Failed test 'Description'
#   in 'xt/dashtap-is_same_env.t'
#     Variable(s) created:
#     Y=added
#     Z=added"

is              "$RC"              1             "Exit status"
file_is         stdout             "$STDOUT"     "Standard output"
file_is         stderr             "$STDERR"     "Standard error"
file_is         trap               "FULL"        "Trap status"

############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "Pass when called with one ignored variable added at end"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >&3' 0
    is_same_env Y "Description" 3<<-"=" 4<<-"-"; RC="$?"
	X=hello1
	=
	X=hello1
	Y=added
	-
    trap - 0
    echo FULL >&3
    exit "$RC"
) >stdout 2>stderr 3>trap; RC="$?"

STDOUT="ok 1 - Description"
STDERR="$NADA"

is              "$RC"              0             "Exit status"
file_is         stdout             "$STDOUT"     "Standard output"
file_is         stderr             "$STDERR"     "Standard error"
file_is         trap               "FULL"        "Trap status"

############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "Fail when called with two variables added at beginning"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >&3' 0
    is_same_env : "Description" 3<<-"=" 4<<-"-"; RC="$?"
	Z=hello2
	=
	X=added
	Y=added2
	Z=hello2
	-
    trap - 0
    echo FULL >&3
    exit "$RC"
) >stdout 2>stderr 3>trap; RC="$?"

STDOUT="not ok 1 - Description"
STDERR="
#   Failed test 'Description'
#   in 'xt/dashtap-is_same_env.t'
#     Variable(s) created:
#     X=added
#     Y=added2"

is              "$RC"              1             "Exit status"
file_is         stdout             "$STDOUT"     "Standard output"
file_is         stderr             "$STDERR"     "Standard error"
file_is         trap               "FULL"        "Trap status"

############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "Pass when called with two ignored variables added at beginning"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >&3' 0
    is_same_env X:Y "Description" 3<<-"=" 4<<-"-"; RC="$?"
	Z=hello2
	=
	X=added
	Y=added2
	Z=hello2
	-
    trap - 0
    echo FULL >&3
    exit "$RC"
) >stdout 2>stderr 3>trap; RC="$?"

STDOUT="ok 1 - Description"
STDERR="$NADA"

is              "$RC"              0             "Exit status"
file_is         stdout             "$STDOUT"     "Standard output"
file_is         stderr             "$STDERR"     "Standard error"
file_is         trap               "FULL"        "Trap status"

############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "Fail when called with one variable removed at end"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >&3' 0
    is_same_env : "Description" 3<<-"=" 4<<-"-"; RC="$?"
	X=hello1
	Y=removed
	Z=removed2
	=
	X=hello1
	-
    trap - 0
    echo FULL >&3
    exit "$RC"
) >stdout 2>stderr 3>trap; RC="$?"

STDOUT="not ok 1 - Description"
STDERR="
#   Failed test 'Description'
#   in 'xt/dashtap-is_same_env.t'
#     Variable(s) unset/removed:
#     Y=removed
#     Z=removed2"

is              "$RC"              1             "Exit status"
file_is         stdout             "$STDOUT"     "Standard output"
file_is         stderr             "$STDERR"     "Standard error"
file_is         trap               "FULL"        "Trap status"

############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "Pass when called with one ignored variable removed at end"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >&3' 0
    is_same_env Y:Z "Description" 3<<-"=" 4<<-"-"; RC="$?"
	X=hello1
	Y=removed
	Z=removed2
	=
	X=hello1
	-
    trap - 0
    echo FULL >&3
    exit "$RC"
) >stdout 2>stderr 3>trap; RC="$?"

STDOUT="ok 1 - Description"
STDERR="$NADA"

is              "$RC"              0             "Exit status"
file_is         stdout             "$STDOUT"     "Standard output"
file_is         stderr             "$STDERR"     "Standard error"
file_is         trap               "FULL"        "Trap status"

############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "Fail when called with one variable removed at beginning"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >&3' 0
    is_same_env : "Description" 3<<-"=" 4<<-"-"; RC="$?"
	X=removed
	Y=removed2
	Z=hello2
	=
	Z=hello2
	-
    trap - 0
    echo FULL >&3
    exit "$RC"
) >stdout 2>stderr 3>trap; RC="$?"

STDOUT="not ok 1 - Description"
STDERR="
#   Failed test 'Description'
#   in 'xt/dashtap-is_same_env.t'
#     Variable(s) unset/removed:
#     X=removed
#     Y=removed2"

is              "$RC"              1             "Exit status"
file_is         stdout             "$STDOUT"     "Standard output"
file_is         stderr             "$STDERR"     "Standard error"
file_is         trap               "FULL"        "Trap status"

############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "Pass when called with two ignored variables removed at beginning"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >&3' 0
    is_same_env X:Y "Description" 3<<-"=" 4<<-"-"; RC="$?"
	X=removed
	Y=removed2
	Z=hello2
	=
	Z=hello2
	-
    trap - 0
    echo FULL >&3
    exit "$RC"
) >stdout 2>stderr 3>trap; RC="$?"

STDOUT="ok 1 - Description"
STDERR="$NADA"

is              "$RC"              0             "Exit status"
file_is         stdout             "$STDOUT"     "Standard output"
file_is         stderr             "$STDERR"     "Standard error"
file_is         trap               "FULL"        "Trap status"

############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "Fail when called with only one variable which is removed"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >&3' 0
    is_same_env : "Description" 3<<-"=" 4<<-"-"; RC="$?"
	X=removed
	=
	-
    trap - 0
    echo FULL >&3
    exit "$RC"
) >stdout 2>stderr 3>trap; RC="$?"

STDOUT="not ok 1 - Description"
STDERR="
#   Failed test 'Description'
#   in 'xt/dashtap-is_same_env.t'
#     Variable(s) unset/removed:
#     X=removed"

is              "$RC"              1             "Exit status"
file_is         stdout             "$STDOUT"     "Standard output"
file_is         stderr             "$STDERR"     "Standard error"
file_is         trap               "FULL"        "Trap status"

############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "Pass when called with only one ignored variable which is removed"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >&3' 0
    is_same_env X "Description" 3<<-"=" 4<<-"-"; RC="$?"
	X=removed
	=
	-
    trap - 0
    echo FULL >&3
    exit "$RC"
) >stdout 2>stderr 3>trap; RC="$?"

STDOUT="ok 1 - Description"
STDERR="$NADA"

is              "$RC"              0             "Exit status"
file_is         stdout             "$STDOUT"     "Standard output"
file_is         stderr             "$STDERR"     "Standard error"
file_is         trap               "FULL"        "Trap status"

############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "Fail when called with no variables and one variable added"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >&3' 0
    is_same_env : "Description" 3<<-"=" 4<<-"-"; RC="$?"
	=
	X=added
	-
    trap - 0
    echo FULL >&3
    exit "$RC"
) >stdout 2>stderr 3>trap; RC="$?"

STDOUT="not ok 1 - Description"
STDERR="
#   Failed test 'Description'
#   in 'xt/dashtap-is_same_env.t'
#     Variable(s) created:
#     X=added"

is              "$RC"              1             "Exit status"
file_is         stdout             "$STDOUT"     "Standard output"
file_is         stderr             "$STDERR"     "Standard error"
file_is         trap               "FULL"        "Trap status"

############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "Pass when called with no variable and one ignored variable added"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >&3' 0
    is_same_env X "Description" 3<<-"=" 4<<-"-"; RC="$?"
	=
	X=added
	-
    trap - 0
    echo FULL >&3
    exit "$RC"
) >stdout 2>stderr 3>trap; RC="$?"

STDOUT="ok 1 - Description"
STDERR="$NADA"

is              "$RC"              0             "Exit status"
file_is         stdout             "$STDOUT"     "Standard output"
file_is         stderr             "$STDERR"     "Standard error"
file_is         trap               "FULL"        "Trap status"

############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "Variable whose name is substring of ignored variable should not be ignored"
(
    unset BAIL_ON_FAIL DIE_ON_FAIL
    dashtap_init
    trap 'echo EXIT >&3' 0
    is_same_env ABCD "Description" 3<<-"=" 4<<-"-"; RC="$?"
	ABCD=one
	BC=first
	=
	ABCD=two
	BC=second
	-
    trap - 0
    echo FULL >&3
    exit "$RC"
) >stdout 2>stderr 3>trap; RC="$?"

STDOUT="not ok 1 - Description"
STDERR="
#   Failed test 'Description'
#   in 'xt/dashtap-is_same_env.t'
#     Variable value(s) changed:
#     BC=first --> second"

is              "$RC"              1             "Exit status"
file_is         stdout             "$STDOUT"     "Standard output"
file_is         stderr             "$STDERR"     "Standard error"
file_is         trap               "FULL"        "Trap status"

############################################################################

done_testing

#[eof]
