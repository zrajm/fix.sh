#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "dashtap/dashtap.sh"
title - <<"EOF"
Should build target with two levels of dependecies which each output
$FIX_LEVEL.
EOF

init_test
mkdir .fix fix src

write_file a+x fix/ZERO.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "ZERO: $FIX_LEVEL"
	fix ONE
	cat "$FIX_TARGET_DIR/ONE"
END_SCRIPT

write_file a+x fix/ONE.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "ONE: $FIX_LEVEL"
	fix TWO
	cat "$FIX_TARGET_DIR/TWO"
END_SCRIPT

write_file a+x fix/TWO.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "TWO: $FIX_LEVEL"
END_SCRIPT

OUTPUT="ZERO: 0
ONE: 1
TWO: 2"

"$TESTCMD" build/ZERO >stdout 2>stderr; RC="$?"

is              "$RC"              0             "Exit status"
file_is         stdout             "$NADA"       "Standard output"
file_is         stderr             "$NADA"       "Standard error"
file_is         build/ZERO         "$OUTPUT"      "Target"

done_testing

#[eof]
