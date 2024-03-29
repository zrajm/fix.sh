#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2016 zrajm <fix@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "dashtap/dashtap.sh"
title - <<"EOF"
Test that --init creates a new .fix directory in the current dir.
EOF

init_test

##############################################################################

"$TESTCMD" --init >stdout 2>stderr; RC="$?"

STDOUT="Initialized empty Fix build state in '$PWD/.fix/'"
STDERR="$NADA"

is              "$RC"              0             "Exit status"
file_not_exists build                            "Default target dir shouldn't exist"
file_not_exists fix                              "Default script dir shouldn't exist"
file_not_exists src                              "Default source dir shouldn't exist"
file_is         stdout             "$STDOUT"     "Standard output"
file_is         stderr             "$STDERR"     "Standard error"
file_exists     .fix                             "Metadata dir should exist"
file_exists     .fix/config                      "Config file should exist"

setread + CONF <".fix/config"
like   "$CONF"  "[core]$NL"              "'[core]' section should exist"
like   "$CONF"  " scriptdir = fix$NL"   "scriptdir should be 'fix'"
like   "$CONF"  " sourcedir = src$NL"    "sourcedir should be 'src'"
like   "$CONF"  " targetdir = build$NL"  "targetdir should be 'build'"

##############################################################################

done_testing

#[eof]
