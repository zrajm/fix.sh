#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "dashtap/dashtap.sh"
title - <<"EOF"
Test that default value of $FIX_SOURCE_DIR is correctly set inside
buildscripts.
EOF

init_test
mkdir .fix src

write_file a+x fix/ZERO.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "ZERO: $FIX_SOURCE_DIR"
	fix ONE
	cat "$FIX_TARGET_DIR/ONE"
END_SCRIPT

write_file a+x fix/ONE.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "ONE: $FIX_SOURCE_DIR"
END_SCRIPT

OUTPUT="ZERO: $PWD/src
ONE: $PWD/src"

"$TESTCMD" build/ZERO >stdout 2>stderr; RC="$?"

is              "$RC"              0             "Exit status"
file_is         stdout             "$NADA"       "Standard output"
file_is         stderr             "$NADA"       "Standard error"
file_is         build/ZERO         "$OUTPUT"      "Target"

done_testing

#[eof]
