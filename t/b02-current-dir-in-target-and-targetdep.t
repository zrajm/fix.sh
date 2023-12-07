#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "dashtap/dashtap.sh"
title - <<"EOF"
Current directory should always be set to $FIX_SOURCE_DIR inside buildscript,
even if the buildscript is invoked from another buildscript (i.e. is building a
dependency) and the invoking buildscript has changed the current directory.
EOF

init_test
mkdir .fix fix src src/SUBDIR

write_file a+x fix/ZERO.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "ZERO: $PWD"
	cd SUBDIR
	fix ONE
	cat "$FIX_TARGET_DIR/ONE"
END_SCRIPT

write_file a+x fix/ONE.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "ONE: $PWD"
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
