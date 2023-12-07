#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2016 zrajm <fix@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "dashtap/dashtap.sh"
title - <<"EOF"
Test that the --script-dir option sets $FIX_SCRIPT_DIR value for the
buildscripts.
EOF

init_test
mkdir .fix src

write_file a+x fix2/ZERO.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "ZERO: $FIX_SCRIPT_DIR"
	fix ONE
	cat "$FIX_TARGET_DIR/ONE"
END_SCRIPT

write_file a+x fix2/ONE.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "ONE: $FIX_SCRIPT_DIR"
END_SCRIPT

OUTPUT="ZERO: $PWD/fix2
ONE: $PWD/fix2"

file_not_exists build/ZERO          "Before build: Target ZERO shouldn't exist"
file_not_exists .fix/state/ZERO     "Before build: Target ZERO metadata shouldn't exist"
file_not_exists build/ONE           "Before build: Target ONE shouldn't exist"
file_not_exists .fix/state/ONE      "Before build: Target ONE metadata shouldn't exist"

"$TESTCMD" build/ZERO >stdout 2>stderr --script-dir=fix2; RC="$?"

META_ZERO="$(
    set -e
    mkmetadata TARGET ZERO     <build/ZERO
    mkmetadata SCRIPT ZERO.fix <fix2/ZERO.fix
    mkmetadata TARGET ONE      <build/ONE
)" || fail "Failed to calculate metadata"
META_ONE="$(
    set -e
    mkmetadata TARGET ONE     <build/ONE
    mkmetadata SCRIPT ONE.fix <fix2/ONE.fix
    #mkmetadata SOURCE SOURCE.txt <src2/SOURCE.txt
)" || fail "Failed to calculate metadata"

is              "$RC"              0             "Exit status"
file_not_exists fix                              "Default script dir shouldn't exist"
file_exists     fix2                             "Script dir should exist"
file_is         stdout             "$NADA"       "Standard output"
file_is         stderr             "$NADA"       "Standard error"

file_is         build/ZERO         "$OUTPUT"     "Target ZERO content"
file_not_exists build/ZERO--fixing               "Target ZERO tempfile shouldn't exist"
file_is         .fix/state/ZERO    "$META_ZERO"  "Target ZERO metadata"
first_dep_is    .fix/state/ZERO    "ZERO"        "Target ZERO metadata first target"
file_not_exists .fix/state/ZERO--fixing          "Target ZERO metadata tempfile shouldn't exist"

file_not_exists build/ONE--fixing                "Target ONE tempfile shouldn't exist"
file_is         .fix/state/ONE     "$META_ONE"   "Target ONE metadata"
first_dep_is    .fix/state/ONE     "ONE"         "Target ONE metadata first target"
file_not_exists .fix/state/ONE--fixing           "Target ONE metadata tempfile shouldn't exist"

done_testing

#[eof]
