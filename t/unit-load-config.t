#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "dashtap/dashtap.sh"
title - <<"EOF"
Unit tests for load_config().
EOF

init_test

# import functions
for FUNC in abspath die is_alphanumeric is_mother load_config relpath say \
        set_dir setrun trim_brackets trim_space; do
    import_function "$FUNC" <"$TESTCMD"
done

################################################################################

title "01. Non-existing inifile should work & set default values"
mkdir "01" && cd "01" && note "DIR: $PWD"

execute trap >stdout 2>stderr 3<<"EOF" 4>env1.txt 5>env2.txt; RC="$?"
    unset FIX_SCRIPT_DIR FIX_SOURCE_DIR FIX_TARGET_DIR
    load_config ini_file "."
EOF
STDOUT="$NADA"
STDERR="$NADA"

file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
is        "$RC"     0          "Exit status"
file_is   trap      "FULL"     "Shouldn't call exit"
is_same_env \
    "RC:FIX_SCRIPT_DIR:FIX_SOURCE_DIR:FIX_TARGET_DIR" \
    "Environment variable leakage" \
    3<env1.txt 4<env2.txt

seteval + ENV stdin <"env2.txt"
like "$ENV" "${NL}FIX_SCRIPT_DIR='$PWD/fix'$NL"   "\$FIX_SCRIPT_DIR default value"
like "$ENV" "${NL}FIX_SOURCE_DIR='$PWD/src'$NL"   "\$FIX_SOURCE_DIR default value"
like "$ENV" "${NL}FIX_TARGET_DIR='$PWD/build'$NL" "\$FIX_TARGET_DIR default value"
cd ..

################################################################################

title "02. Inifile with hash & semicolon comments, and blank lines should work"
mkdir "02" && cd "02" && note "DIR: $PWD"

write_file ini_file <<-"END_CONF"
	# hash comment
	; semi-colon comment

	[core]

	    # indented hash comment
	    ; semi-colon comment
	    scriptdir = script-y
	    sourcedir = source-y
	    targetdir = target-y
END_CONF

execute trap >stdout 2>stderr 3<<"EOF" 4>env1.txt 5>env2.txt; RC="$?"
    unset FIX_SCRIPT_DIR FIX_SOURCE_DIR FIX_TARGET_DIR
    load_config ini_file "."
EOF
STDOUT="$NADA"
STDERR="$NADA"

file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
is        "$RC"     0          "Exit status"
file_is   trap      "FULL"     "Shouldn't call exit"
is_same_env \
    "RC:FIX_SCRIPT_DIR:FIX_SOURCE_DIR:FIX_TARGET_DIR" \
    "Environment variable leakage" \
     3<env1.txt 4<env2.txt

seteval + ENV stdin <"env2.txt"
like "$ENV" "${NL}FIX_SCRIPT_DIR='$PWD/script-y'$NL" "'scriptdir' should set \$FIX_SCRIPT_DIR"
like "$ENV" "${NL}FIX_SOURCE_DIR='$PWD/source-y'$NL" "'sourcedir' should set \$FIX_SOURCE_DIR"
like "$ENV" "${NL}FIX_TARGET_DIR='$PWD/target-y'$NL" "'targetdir' should set \$FIX_TARGET_DIR"
cd ..

################################################################################

title "03. Inifile with no newline on last line should work"
mkdir "03" && cd "03" && note "DIR: $PWD"

# Write inifile that doesn't end in newline.
printf "%s\n%s" "[core]" "scriptdir = random" >ini_file

execute trap >stdout 2>stderr 3<<"EOF" 4>env1.txt 5>env2.txt; RC="$?"
    unset FIX_SCRIPT_DIR FIX_SOURCE_DIR FIX_TARGET_DIR
    load_config ini_file "."
EOF
STDOUT="$NADA"
STDERR="$NADA"

file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
is        "$RC"     0          "Exit status"
file_is   trap      "FULL"     "Shouldn't call exit"
is_same_env \
    "RC:FIX_SCRIPT_DIR:FIX_SOURCE_DIR:FIX_TARGET_DIR" \
    "Environment variable leakage" \
     3<env1.txt 4<env2.txt

seteval + ENV stdin <"env2.txt"
like "$ENV" "${NL}FIX_SCRIPT_DIR='$PWD/random'$NL" "'scriptdir' should set \$FIX_SCRIPT_DIR"
# Intentionally not testing FIX_SOURCE_DIR and FIX_TARGET_DIR here
cd ..

################################################################################

# This behaviour differs from Git, but its probably a common enough error to
# warrant an error message. (And allowing unknown section names + config
# variables gives future compatibility, whilst allowing config variables
# outside sections does not improve future compatibility.)

title "04. Config variables in inifile before any '[section]' should fail"
mkdir "04" && cd "04" && note "DIR: $PWD"

write_file ini_file <<-"END_CONF"
	scriptdir = script-y
	sourcedir = source-y
	targetdir = target-y
END_CONF

# die()s, so can't test for environment leaks.
execute trap >stdout 2>stderr 3<<"EOF"; RC="$?"
    load_config ini_file "."
EOF
STDOUT="$NADA"
STDERR="ERROR: Config variable 'scriptdir' above section in file 'ini_file' (above sections)
    (Must be under a '[section]' heading.)"

file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
is        "$RC"     9          "Exit status"
file_is   trap      "EXIT"     "Should call exit"
cd ..

################################################################################

title "05. Inifile with non-alphanumeric [section] name should fail"
mkdir "05" && cd "05" && note "DIR: $PWD"

write_file ini_file <<-"END_CONF"
	[VALID_SECTION_NAME]
	[INVALID-SECTION-NAME]
END_CONF

# die()s, so can't test for environment leaks.
execute trap >stdout 2>stderr 3<<"EOF"; RC="$?"
    load_config ini_file "."
EOF
STDOUT="$NADA"
STDERR="ERROR: Invalid section name '[INVALID-SECTION-NAME]' in file 'ini_file' (section '[VALID_SECTION_NAME]')
    (Must be alphanumeric and start with non-number.)"

file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
is        "$RC"     9          "Exit status"
file_is   trap      "EXIT"     "Should call exit"
cd ..

################################################################################

title "06. Unknown [section] name should be silently ignored"
mkdir "06" && cd "06" && note "DIR: $PWD"

write_file ini_file <<-"END_CONF"
	[Some_section_name_123]
END_CONF

execute trap >stdout 2>stderr 3<<"EOF" 4>env1.txt 5>env2.txt; RC="$?"
    load_config ini_file "."
EOF
STDOUT="$NADA"
STDERR="$NADA"

file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
is        "$RC"     0          "Exit status"
file_is   trap      "FULL"     "Shouldn't call exit"
is_same_env \
    "RC:FIX_SCRIPT_DIR:FIX_SOURCE_DIR:FIX_TARGET_DIR" \
    "Environment variable leakage" \
     3<env1.txt 4<env2.txt
cd ..

################################################################################

title "07. Environment var with abspath should be kept, not overridden by config"
mkdir "07" && cd "07" && note "DIR: $PWD"

write_file ini_file <<-"END_CONF"
	[core]
	    scriptdir = file1
	    sourcedir = file2
	    targetdir = file3
END_CONF

execute trap >stdout 2>stderr 3<<"EOF" 4>env1.txt 5>env2.txt; RC="$?"
    FIX_SCRIPT_DIR=/env1
    FIX_SOURCE_DIR=/env2
    FIX_TARGET_DIR=/env3
    load_config ini_file "."
EOF
STDOUT="$NADA"
STDERR="$NADA"

file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
is        "$RC"     0          "Exit status"
file_is   trap      "FULL"     "Shouldn't call exit"
is_same_env \
    "RC:FIX_SCRIPT_DIR:FIX_SOURCE_DIR:FIX_TARGET_DIR" \
    "Environment variable leakage" \
     3<env1.txt 4<env2.txt

seteval + ENV stdin <"env2.txt"
like "$ENV" "${NL}FIX_SCRIPT_DIR='/env1'$NL" "\$FIX_SCRIPT_DIR should not be changed"
like "$ENV" "${NL}FIX_SOURCE_DIR='/env2'$NL" "\$FIX_SOURCE_DIR should not be changed"
like "$ENV" "${NL}FIX_TARGET_DIR='/env3'$NL" "\$FIX_TARGET_DIR should not be changed"
cd ..

################################################################################

title "08. Environment var with relpath changed to abspath, but not overridden"
mkdir "08" && cd "08" && note "DIR: $PWD"

write_file ini_file <<-"END_CONF"
	[core]
	    scriptdir = file1
	    sourcedir = file2
	    targetdir = file3
END_CONF

execute trap >stdout 2>stderr 3<<"EOF" 4>env1.txt 5>env2.txt; RC="$?"
    FIX_SCRIPT_DIR=env1
    FIX_SOURCE_DIR=env2
    FIX_TARGET_DIR=env3
    load_config ini_file "."
EOF
STDOUT="$NADA"
STDERR="$NADA"

file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
is        "$RC"     0          "Exit status"
file_is   trap      "FULL"     "Shouldn't call exit"
is_same_env \
    "RC:FIX_SCRIPT_DIR:FIX_SOURCE_DIR:FIX_TARGET_DIR" \
    "Environment variable leakage" \
     3<env1.txt 4<env2.txt

seteval + ENV stdin <"env2.txt"
like "$ENV" "${NL}FIX_SCRIPT_DIR='$PWD/env1'$NL" "\$FIX_SCRIPT_DIR should not be changed"
like "$ENV" "${NL}FIX_SOURCE_DIR='$PWD/env2'$NL" "\$FIX_SOURCE_DIR should not be changed"
like "$ENV" "${NL}FIX_TARGET_DIR='$PWD/env3'$NL" "\$FIX_TARGET_DIR should not be changed"
cd ..

################################################################################

title "09. Non-alphanumeric config variables in inifile name should fail"
mkdir "09" && cd "09" && note "DIR: $PWD"

write_file ini_file <<-"END_CONF"
	[core]
	    BAD-VAR-NAME = whatevs
END_CONF

# die()s, so can't test for environment leaks.
execute trap >stdout 2>stderr 3<<"EOF" 4>env1.txt 5>env2.txt; RC="$?"
    load_config ini_file "."
EOF
STDOUT="$NADA"
STDERR="ERROR: Invalid config variable name 'BAD-VAR-NAME' in file 'ini_file' (section '[core]')
    (Must be alphanumeric and start with non-number.)"

file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
is        "$RC"     9          "Exit status"
file_is   trap      "EXIT"     "Should call exit"
cd ..

################################################################################

title "10. Syntax error should fail"
mkdir "10" && cd "10" && note "DIR: $PWD"

write_file ini_file <<-"END_CONF"
	[core]
	    SYNTAX ERROR
END_CONF

# die()s, so can't test for environment leaks.
execute trap >stdout 2>stderr 3<<"EOF" 4>env1.txt 5>env2.txt; RC="$?"
    load_config ini_file "."
EOF
STDOUT="$NADA"
STDERR="ERROR: Error in 'SYNTAX ERROR' in file 'ini_file' (section '[core]')
    (Must contain '[section]', 'var = value', or '# comment'.)"

file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
is        "$RC"     9          "Exit status"
file_is   trap      "EXIT"     "Should call exit"
cd ..

################################################################################

title "11. Unknown config variables in inifile should be silently ignored"
mkdir "11" && cd "11" && note "DIR: $PWD"

write_file ini_file <<-"END_CONF"
	[core]
	    NON_OPTION = file1
END_CONF

execute trap >stdout 2>stderr 3<<"EOF" 4>env1.txt 5>env2.txt; RC="$?"
    load_config ini_file "."
EOF
STDOUT="$NADA"
STDERR="$NADA"

file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
is        "$RC"     0          "Exit status"
file_is   trap      "FULL"     "Shouldn't call exit"
is_same_env \
    "RC:FIX_SCRIPT_DIR:FIX_SOURCE_DIR:FIX_TARGET_DIR" \
    "Environment variable leakage" \
     3<env1.txt 4<env2.txt

seteval + ENV stdin <"env2.txt"
like "$ENV" "${NL}FIX_SCRIPT_DIR='$PWD/fix'$NL"   "\$FIX_SCRIPT_DIR default value"
like "$ENV" "${NL}FIX_SOURCE_DIR='$PWD/src'$NL"   "\$FIX_SOURCE_DIR default value"
like "$ENV" "${NL}FIX_TARGET_DIR='$PWD/build'$NL" "\$FIX_TARGET_DIR default value"
cd ..

################################################################################

title "12. Invoking load_config() with wrong number of args should fail"
mkdir "12" && cd "12" && note "DIR: $PWD"

# die()s, so can't test for environment leaks.
execute trap >stdout 2>stderr 3<<"EOF"; RC="$?"
    load_config ini_file
EOF
STDOUT="$NADA"
STDERR="ERROR: load_config: Bad number of args"

file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
is        "$RC"     9          "Exit status"
file_is   trap      "EXIT"     "Should call exit"
cd ..

################################################################################

done_testing

#[eof]
