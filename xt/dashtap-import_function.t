#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]
. "t/dashtap.sh"
NADA=""; strip_newline NADA                    # NADA = '\No newline at end'

##############################################################################

function_exists     import_function    "Function 'import_function' exists"

##############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "import_function: Invoked without input on STDIN"
execute trap >stdout 2>stderr 3<<"EOF"; RC="$?"
    import_function
EOF
STDOUT="$NADA"
STDERR="import_function: No input on stdin"

is        "$RC"     255        "Exit status"
file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
file_is   trap      "EXIT"     "Should call exit"

##############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "import_function: Invoked without arguments"
execute trap >stdout 2>stderr 3<<"EOF"; RC="$?"
    import_function <<-END_SCRIPT
	END_SCRIPT
EOF
STDOUT="$NADA"
STDERR="import_function: Bad number of args"

is        "$RC"     255        "Exit status"
file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
file_is   trap      "EXIT"     "Should call exit"

##############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "import_function: Called with bad function name"
execute trap >stdout 2>stderr 3<<"EOF"; RC="$?"
    import_function %@!# <<-END_SCRIPT
	END_SCRIPT
EOF
STDOUT="$NADA"
STDERR="import_function: Bad function name '%@!#'"

is        "$RC"     255        "Exit status"
file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
file_is   trap      "EXIT"     "Should call exit"

##############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "import_function: Importing non-existing function"
execute trap >stdout 2>stderr 3<<"EOF"; RC="$?"
    import_function non_existing <<-END_SCRIPT
	existing() {
	    :
	}
	END_SCRIPT
    non_existing  # should've died before this
EOF
STDOUT="$NADA"
STDERR="import_function: Function 'non_existing' not found in input"

is        "$RC"     255        "Exit status"
file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
file_is   trap      "EXIT"     "Should call exit"

##############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "import_function: Importing existing function"
execute trap >stdout 2>stderr 3<<"EOF"; RC="$?"
    import_function existing <<-END_SCRIPT
	existing() {
	    echo "FUNC OUTPUT"
	}
	END_SCRIPT
    existing  # call imported function
EOF
STDOUT="FUNC OUTPUT"
STDERR="$NADA"

is        "$RC"     0          "Exit status"
file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
file_is   trap      "FULL"     "Shouldn't call exit"

##############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "import_function: Importing already existing function"
execute trap >stdout 2>stderr 3<<"EOF"; RC="$?"
    already_existing() { echo "ORIGINAL FUNC OUTPUT"; }
    import_function already_existing <<-END_SCRIPT
	already_existing() {
	    echo "IMPORTED FUNC OUTPUT"
	}
	END_SCRIPT
    already_existing  # should've died before this
EOF
STDOUT="$NADA"
STDERR="import_function: Function 'already_existing' already exists"

is        "$RC"     255        "Exit status"
file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
file_is   trap      "EXIT"     "Should call exit"

##############################################################################

cd "$(mktemp -d)" && note "DIR: $PWD"
title "import_function: Importing already function with syntax error"
execute trap >stdout 2>stderr 3<<"EOF"; RC="$?"
    import_function syntax_error <<-END_SCRIPT
	syntax_error() {
	    echo "OUTPUT" |         # intentional syntax error
	}
	END_SCRIPT
    syntax_error  # should've died before this
EOF
STDOUT="$NADA"

STDERR="import_function: Function 'syntax_error' eval failed: Syntax error: \"}\" unexpected"

is        "$RC"     255        "Exit status"
file_is   stdout    "$STDOUT"  "Standard output"
file_is   stderr    "$STDERR"  "Standard error"
file_is   trap      "EXIT"     "Should call exit"

##############################################################################

done_testing

#[eof]
