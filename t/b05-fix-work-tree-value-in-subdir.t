#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "dashtap/dashtap.sh"
title - <<"EOF"
Should test that $FIX_WORK_TREE is correctly set everywhere, when running Fix
from inside a subdir in the work tree.
EOF

init_test
mkdir .fix fix src SUBDIR

write_file a+x fix/ZERO.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "ZERO: $FIX_WORK_TREE"
	fix ONE
	cat "$FIX_TARGET_DIR/ONE"
END_SCRIPT

write_file a+x fix/ONE.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	echo "ONE: $FIX_WORK_TREE"
END_SCRIPT

OUTPUT="ZERO: $PWD
ONE: $PWD"

cd SUBDIR || fail "Cannot change current dir to 'SUBDIR'"
"$TESTCMD" ../build/ZERO >"../stdout" 2>"../stderr"; RC="$?"
cd ..     || fail "Cannot change current dir back to work tree root"

is              "$RC"              0             "Exit status"
file_is         stdout             "$NADA"       "Standard output"
file_is         stderr             "$NADA"       "Standard error"
file_is         build/ZERO         "$OUTPUT"      "Target"

done_testing

#[eof]
