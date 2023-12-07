#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "dashtap/dashtap.sh"
title - <<"EOF"
Should output the name of the tempfile connected to standard output, when
printing the arguments received by the buildscript.
EOF

init_test
mkdir .fix fix src

write_file a+x fix/TARGET.fix <<-"END_SCRIPT"
	#!/bin/sh
	set -eu
	for ARG; do
	    echo ">$ARG<"
	done
END_SCRIPT

OUTPUT=">$PWD/build/TARGET--fixing<"

"$TESTCMD" build/TARGET >stdout 2>stderr; RC="$?"

is              "$RC"              0             "Exit status"
file_is         stdout             "$NADA"       "Standard output"
file_is         stderr             "$NADA"       "Standard error"
file_is         build/TARGET       "$OUTPUT"     "Target"

done_testing

#[eof]
