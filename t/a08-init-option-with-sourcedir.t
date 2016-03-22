#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2016 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Test that --source-dir, when used with --init, writes the specified sourcedir
to the config file.
EOF

init_test

##############################################################################

"$TESTCMD" --source-dir=HELLO --init >stdout 2>stderr; RC="$?"

is              "$RC"              0             "Exit status"
file_not_exists build                            "Default target dir shouldn't exist"
file_not_exists fix                              "Default script dir shouldn't exist"
file_not_exists src                              "Default source dir shouldn't exist"
file_is         stdout             "$NADA"       "Standard output"
file_is         stderr             "$NADA"       "Standard error"
file_exists     .fix                             "Metadata dir should exist"
file_exists     .fix/config                      "Config file should exist"

setread + CONF <".fix/config"
like   "$CONF"  "[core]$NL"              "'[core]' section should exist"
like   "$CONF"  " scriptdir = fix$NL"    "scriptdir should be 'fix'"
like   "$CONF"  " sourcedir = HELLO$NL"  "sourcedir should be 'HELLO'"
like   "$CONF"  " targetdir = build$NL"  "targetdir should be 'build'"

##############################################################################

done_testing

#[eof]
