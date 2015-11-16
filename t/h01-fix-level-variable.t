#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Should build target with two levels of dependecies which each output
$FIX_LEVEL.
EOF

init_test
mkdir fix src

write_file a+x fix/ZERO.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "ZERO: $FIX_LEVEL"
	$FIX ONE
	cat "$FIX_TARGET_DIR/ONE"
END_SCRIPT

write_file a+x fix/ONE.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "ONE: $FIX_LEVEL"
	$FIX TWO
	cat "$FIX_TARGET_DIR/TWO"
END_SCRIPT

write_file a+x fix/TWO.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "TWO: $FIX_LEVEL"
END_SCRIPT

OUTPUT="ZERO: 0
ONE: 1
TWO: 2"

"$TESTCMD" ZERO >stdout 2>stderr; RC="$?"

is              "$RC"              0             "Exit status"
file_is         stdout             "$NADA"       "Standard output"
file_is         stderr             "$NADA"       "Standard error"
file_is         build/ZERO         "$OUTPUT"      "Target"

done_testing

#[eof]
