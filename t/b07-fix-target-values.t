#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Should build target with two levels of dependecies which each output
$FIX_TARGET.
EOF

init_test
mkdir .fix fix src

write_file a+x fix/ZERO.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "ZERO: >$FIX_TARGET<"
	fix ONE
	cat "$FIX_TARGET_DIR/ONE"
END_SCRIPT

write_file a+x fix/ONE.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "ONE: >$FIX_TARGET<"
	fix TWO
	cat "$FIX_TARGET_DIR/TWO"
END_SCRIPT

write_file a+x fix/TWO.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "TWO: >$FIX_TARGET<"
END_SCRIPT

OUTPUT="ZERO: >ZERO<
ONE: >ONE<
TWO: >TWO<"

"$TESTCMD" build/ZERO >stdout 2>stderr; RC="$?"

is              "$RC"              0             "Exit status"
file_is         stdout             "$NADA"       "Standard output"
file_is         stderr             "$NADA"       "Standard error"
file_is         build/ZERO         "$OUTPUT"      "Target"

done_testing

#[eof]
