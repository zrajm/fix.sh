#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Test that default value of $FIX_TARGET_DIR is correctly set inside
buildscripts.
EOF

init_test
mkdir src

write_file a+x fix/ZERO.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "ZERO: $FIX_TARGET_DIR"
	fix ONE
	cat "$FIX_TARGET_DIR/ONE"
END_SCRIPT

write_file a+x fix/ONE.fix <<-"END_SCRIPT"
	#!/bin/sh
	echo "ONE: $FIX_TARGET_DIR"
END_SCRIPT

OUTPUT="ZERO: $PWD/build
ONE: $PWD/build"

"$TESTCMD" ZERO >stdout 2>stderr; RC="$?"

is              "$RC"              0             "Exit status"
file_is         stdout             "$NADA"       "Standard output"
file_is         stderr             "$NADA"       "Standard error"
file_is         build/ZERO         "$OUTPUT"      "Target"

done_testing

#[eof]
