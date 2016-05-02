#!/usr/bin/env dash

# -*- sh -*-
# Copyright (C) 2016 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
title - <<"EOF"
Unit tests for save_config().
EOF

init_test

################################################################################

# Mock functions.
load_config() { :; }
setrun() {
    case "$1" in
        SCRIPT_DIR) SCRIPT_DIR='<SCRIPT>' ;;
        SOURCE_DIR) SOURCE_DIR='<SOURCE>' ;;
        TARGET_DIR) TARGET_DIR='<TARGET>' ;;
    esac
}

# Import functions.
for FUNC in save_config read_stdin say die is_mother; do
    import_function "$FUNC" <"$TESTCMD"
done

################################################################################

title "01. Writing default config file should work"
mkdir "01" && cd "01" && note "DIR: $PWD"

execute trap >stdout 2>stderr 3<<"EOF" 4>env1.txt 5>env2.txt; RC="$?"
    save_config ini_file "."
EOF
STDOUT="$NADA"
STDERR="$NADA"
INIFILE="[core]
    scriptdir = <SCRIPT>
    sourcedir = <SOURCE>
    targetdir = <TARGET>"

file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
is        "$RC"     0          "Exit status"
file_is   trap      "FULL"     "Shouldn't call exit"
file_is   ini_file  "$INIFILE" "Inifile content"
is_same_env \
    "RC" \
    "Environment variable leakage" \
    3<env1.txt 4<env2.txt
cd ..

################################################################################

title "02. Calling with wrong number of arguments should fail"
mkdir "02" && cd "02" && note "DIR: $PWD"

execute trap >stdout 2>stderr 3<<"EOF"; RC="$?"
    save_config WRONG NUMBER OF ARGS
EOF
STDOUT="$NADA"
STDERR="ERROR: save_config: Bad number of args"

file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
is        "$RC"     13         "Exit status"
file_is   trap      "EXIT"     "Should call exit"
file_not_exists     ini_file   "Inifile shouldn't be created"
cd ..

################################################################################

done_testing

#[eof]
