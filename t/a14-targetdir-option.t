#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2016 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "dashtap/dashtap.sh"
title - <<"EOF"
Test that the --target-dir option sets $FIX_TARGET_DIR value for the
buildscripts.
EOF

init_test
mkdir .fix src

write_file a+x fix/ZERO.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "ZERO: $FIX_TARGET_DIR"
	fix ONE
	cat "$FIX_TARGET_DIR/ONE"
END_SCRIPT

write_file a+x fix/ONE.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "ONE: $FIX_TARGET_DIR"
END_SCRIPT

OUTPUT="ZERO: $PWD/build2
ONE: $PWD/build2"

file_not_exists build2/ZERO         "Before build: Target ZERO shouldn't exist"
file_not_exists .fix/state/ZERO     "Before build: Target ZERO metadata shouldn't exist"
file_not_exists build2/ONE          "Before build: Target ONE shouldn't exist"
file_not_exists .fix/state/ONE      "Before build: Target ONE metadata shouldn't exist"

"$TESTCMD" build2/ZERO >stdout 2>stderr --target-dir=build2; RC="$?"

META_ZERO="$(
    set -e
    mkmetadata TARGET ZERO     <build2/ZERO
    mkmetadata SCRIPT ZERO.fix <fix/ZERO.fix
    mkmetadata TARGET ONE      <build2/ONE
)" || fail "Failed to calculate metadata"
META_ONE="$(
    set -e
    mkmetadata TARGET ONE     <build2/ONE
    mkmetadata SCRIPT ONE.fix <fix/ONE.fix
    #mkmetadata SOURCE SOURCE.txt <src2/SOURCE.txt
)" || fail "Failed to calculate metadata"

is              "$RC"               0            "Exit status"
file_not_exists build                            "Default target dir shouldn't exist"
file_exists     build2                           "Target dir should exist"
file_is         stdout              "$NADA"      "Standard output"
file_is         stderr              "$NADA"      "Standard error"

file_is         build2/ZERO         "$OUTPUT"    "Target ZERO content"
file_not_exists build2/ZERO--fixing              "Target ZERO tempfile shouldn't exist"
file_is         .fix/state/ZERO     "$META_ZERO" "Target ZERO metadata"
first_dep_is    .fix/state/ZERO     "ZERO"       "Target ZERO metadata first target"
file_not_exists .fix/state/ZERO--fixing          "Target ZERO metadata tempfile shouldn't exist"

file_not_exists build2/ONE--fixing               "Target ONE tempfile shouldn't exist"
file_is         .fix/state/ONE      "$META_ONE"  "Target ONE metadata"
first_dep_is    .fix/state/ONE      "ONE"        "Target ONE metadata first target"
file_not_exists .fix/state/ONE--fixing           "Target ONE metadata tempfile shouldn't exist"

done_testing

#[eof]
