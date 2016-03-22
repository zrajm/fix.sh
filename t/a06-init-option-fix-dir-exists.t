#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2016 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Test that --init fails (and does not create a config file) if '.fix/' dir
already exists.
EOF

init_test
mkdir .fix

##############################################################################

prefix "Before build"
file_exists     .fix                             "Metadata dir should exist"

"$TESTCMD" --init >stdout 2>stderr; RC="$?"

STDOUT="$NADA"
STDERR="ERROR: Fix dir '.fix' already exists"

is              "$RC"              1             "Exit status"
file_not_exists build                            "Default target dir shouldn't exist"
file_not_exists fix                              "Default script dir shouldn't exist"
file_not_exists src                              "Default source dir shouldn't exist"
file_is         stdout             "$STDOUT"     "Standard output"
file_is         stderr             "$STDERR"     "Standard error"
file_exists     .fix                             "Metadata dir should exist"
file_not_exists .fix/config                      "Config file shouldn't exist"

##############################################################################

done_testing

#[eof]
