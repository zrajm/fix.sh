#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Unit tests for parseopts().
EOF
init_test

for FUNC in die is_mother read_stdin setrun parseopts_case_code parseopts; do
    import_function "$FUNC" <"$TESTCMD"
done

say() { printf "%s\n" "$@"; }                  # safe 'echo'

##############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "parseopts: '--' option with optarg should fail"
execute trap >stdout 2>stderr 3<<"EOF"; RC="$?"
    parseopts say --="xxx" <<-"END_OPTS"
	END_OPTS
EOF
STDOUT="$NADA"
STDERR="ERROR: Unknown option '--=xxx'
    (Try '${0##*/} --help' for more information.)"

is        "$RC"     15         "Exit status"
file_is   trap      "EXIT"     "Should call exit"
file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"

##############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "parseopts: '--' option without optarg should work"
execute trap >stdout 2>stderr 3<<"EOF"; RC="$?"
    parseopts say aaa -- bbb <<-"END_OPTS"
	END_OPTS
EOF
STDOUT="aaa
bbb"
STDERR="$NADA"

is        "$RC"     0          "Exit status"
file_is   trap      "FULL"     "Shouldn't call exit"
file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"

##############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "parseopts: '--unknown' should cause error"
execute trap >stdout 2>stderr 3<<"EOF"; RC="$?"
    parseopts say --unknown <<-"END_OPTS"
	END_OPTS
EOF
STDOUT="$NADA"
STDERR="ERROR: Unknown option '--unknown'
    (Try '${0##*/} --help' for more information.)"

is        "$RC"     15         "Exit status"
file_is   trap      "EXIT"     "Should call exit"
file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"

##############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "parseopts: '--unknown=arg' should cause same error as '--unknown'"
execute trap >stdout 2>stderr 3<<"EOF"; RC="$?"
    parseopts say --unknown=arg <<-"END_OPTS"
	END_OPTS
EOF
STDOUT="$NADA"
STDERR="ERROR: Unknown option '--unknown'
    (Try '${0##*/} --help' for more information.)"

is        "$RC"     15         "Exit status"
file_is   trap      "EXIT"     "Should call exit"
file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"

##############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "parseopts: Unknown shortopt should cause error"
execute trap >stdout 2>stderr 3<<"EOF"; RC="$?"
    parseopts say -u <<-"END_OPTS"
	END_OPTS
EOF
STDOUT="$NADA"
STDERR="ERROR: Unknown option '-u'
    (Try '${0##*/} --help' for more information.)"

is        "$RC"     15         "Exit status"
file_is   trap      "EXIT"     "Should call exit"
file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"

##############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "parseopts: Longoptions with arguments should work"
execute trap >stdout 2>stderr 3<<"EOF"; RC="$?"
    parseopts say --force --opt1=foo --opt2 bar -- --force <<-"END_OPTS"
	--force) FORCE=1 ;;
	--opt1)  OPT1="$1"; OPTARG=used ;;
	--opt2)  OPT2="$1"; OPTARG=used ;;
	END_OPTS
    say "FORCE=$FORCE"
    say "OPT1=foo"
    say "OPT2=bar"
EOF
STDOUT="--force
FORCE=1
OPT1=foo
OPT2=bar"
STDERR="$NADA"

is        "$RC"     0          "Exit status"
file_is   trap      "FULL"     "Shouldn't call exit"
file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"

##############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "parseopts: Option that doesn't take arg should fail with '=arg'"
execute trap >stdout 2>stderr 3<<"EOF"; RC="$?"
    parseopts say --force=arg <<-"END_OPTS"
	--force) FORCE=1 ;;
	END_OPTS
EOF
STDOUT="$NADA"
STDERR="ERROR: Option '--force' doesn't allow an argument
    (Try '${0##*/} --help' for more information.)"

is        "$RC"     15         "Exit status"
file_is   trap      "EXIT"     "Should call exit"
file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"

##############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "parseopts: Option that requires arg should fail without it"
execute trap >stdout 2>stderr 3<<"EOF"; RC="$?"
    parseopts say --opt <<-"END_OPTS"
	--opt) OPT="$1"; OPTARG=used ;;
	END_OPTS
EOF
STDOUT="$NADA"
STDERR="ERROR: Option '--opt' requires an argument
    (Try '${0##*/} --help' for more information.)"

is        "$RC"     15         "Exit status"
file_is   trap      "EXIT"     "Should call exit"
file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"

##############################################################################

done_testing

#[eof]
