# -*- sh -*-

## DASHTAP
## =======
## This is the Dashtap testing system. Written in dash (Debian Almquist SHell)
## and featuring TAP (the Test Anything Protocol) of Perl fame.
##
## This test system strives to as similar to the Perl Test::More module as
## possible, while still making the writing of reliable tests easy and fun
## using shellscripts only. You may find it useful for end-to-end test of
## command line tools (written in any language), or maybe to write unit tests
## for shell scripts (see also "WRITING SHELL SCRIPT UNIT TESTS" below).
##
## I wrote this since I needed something lightingly fast to test my 'fix' build
## system with, and since TAP is such a nice and easy-to-work with format for
## test output (with plenty of useful tools readily available, most important
## of which is prove(1) that comes with the standard Perl distribution).
##
## ENVIRONMENT VARIABLE OPTIONS
## ============================
## Set these variables to a non-empty string to get the described effect.
## (Variable names are chosen to be compatible with Test::Most.)
##
##   * BAIL_ON_FAIL - abort on first test fail
##   *  DIE_ON_FAIL - skip remaining tests in file when test fail
##
## SHELL TESTING CAVEATS
## =====================
## 1. Don't use $(...)/`...` to produce strings that are to be tested!
##
##    The shell $(...)/`...` construct STRIPS ALL TRAILING NEWLINES, which
##    makes it too inaccurate for testing purposes. (Texts which differ only in
##    the number of trailing newlines will be considered the same in tests, and
##    be indistinguishable from each other in user messages -- leading to
##    errors that are very hard to track down.) The following code is therefore
##    (subtly) broken:
##
##        # BROKEN EXAMPLE -- DON'T USE
##        fail "$DESCR" <<-EOF
##                $(indent "GOT   :" "$GOT")
##                $(indent "WANTED:" "$WANTED")
##        EOF
##
##    This innocently looking example is also broken. (It looks as if the test
##    is carefully matching against a newline ['\n'] at the end of $A, but the
##    $(...) construct strip trailing newlines, so actually the comparison
##    checks that $A = "a" [without newline]!)
##
##        # BROKEN EXAMPLE -- DON'T USE
##        is "$A" "$(printf 'a\n')"
##
##    You can mitigate this problem by adding a non-newline (e.g. a period)
##    character to the end of the strings to be compared, but this leaves you
##    with an extra unwanted character in any error messages output to the
##    user. :(
##
##        # Ugly, but working example (leaves extra '.' in error output)
##        is "$A." "$(printf 'a\n.')"
##
##    For a better solution, see below.
##
## 2. Don't put a test function (inside or) after a pipe!
##
##    Each part of a pipe is executed in its own subshell, meaning that
##    variables set inside a command pipeline CANNOT be seen by the surrounding
##    shell. This means that if you put your test function (any function that
##    call 'pass' or 'fail') in a pipe, it cannot update the global $TEST_COUNT
##    variable, meaning that your test count will not agree with the number of
##    'ok' (and 'not ok') in your TAP output. The following code is therefore
##    also (subtly) broken:
##
##        # BROKEN EXAMPLE -- DON'T USE
##        {
##            indent "GOT   :" "$GOT"
##            indent "WANTED:" "$WANTED"
##        } | fail "$DESCR"
##
## Workaround
## ----------
##     The helper function 'seteval' can be used to avoid the above constructs,
##     and preserve any trailing newlines (see 'seteval' below), while still
##     give you neat and accurate error messages. E.g.
##
##         seteval GOT    'indent "GOT   :" "$GOT"'
##         seteval WANTED 'indent "WANTED:" "$WANTED"'
##         fail "$DESCR" <<-EOF
##                 $GOT
##                 $WANTED
##                 EOF
##
## WRITING SHELL SCRIPT UNIT TESTS
## ===============================
##
## When writing unit tests (as opposed to end-to-end tests) for shell scripts
## the shell script needs to be broken down into smaller, testable parts. This
## is done by breaking the script into functions, and then writing the script
## in such a way that it is possible both to (a) run it normally and (b) get
## access to all its functions without actually running the script itself.
##
## There are two ways of running a shell script, one is by 'sourcing' it --
## this is done by the '.' command (in newer shells 'source' is also a command
## which does the same thing). When you source a shellscript, it runs in the
## environment of a parent shell, and all its functions and (non-local)
## variables will remain in that shell, even after the shell is done running.
## (Normally you don't source shell scripts, except for your shell shartup
## files, which configure aliases and other convenient stuff.)
##
## The other way is by executing the script (this in the most common way). You
## execute a script by either specifying which shell to use ('bash SCRIPTNAME')
## or, if the script has its 'x' bit set, you can rely on the scripts shebang
## line and execute the script directly ('./SCRIPTNAME').
##
## Now we add a small piece of code that will execute the script's main
## function only if it is executed, but not if it is sourced. (This is similar
## to brian d foy's "modulino" trick used by many Perl hackers to simplify unit
## testing.)
##
## Since sourcing exports all its functions is ideal to use when testing, while
## executing is better suited to the everyday running the script in question.
## To make this work however, the actual script functionality should only be
## invoked when executed, but not when sourced.
##
## This can be done by looking at the $0 variable (which contains the name of
## the running process) to see whether it contains the script name or not, like
## this:
##
##     # call main function script was executed (not sourced)
##     [ "${0##*/}" = SCRIPTNAME ] && main "$@"
##
## NOTE: At first sight it might seem that checking to see whether $0 is equal
## to bash/dash/zsh would be a good idea, but doing that will fail if the
## script is sourced from inside another script. (Such as when using Dashtap.)
##
## NOTE II: In zsh the option FUNCTION_ARGZERO must be unset for $0 to be set
## so that the above code will work.
##

##############################################################################
##                                                                          ##
##  Test Functions                                                          ##
##                                                                          ##
##############################################################################

TEST_COUNT=0                                   # tests performed
TEST_FAILS=0                                   # failed tests
TEST_PLANNED=-1                                # plan (set by done_testing)
TEST_TODO=""                                   # TODO reason (if any)
TEST_SKIP=""                                   # SKIP reason (if any)
trap 'on_exit; trap - 0' 0                     # exit messages
on_exit() {
    if [ $TEST_COUNT = 0 ]; then
        diag "No tests run!"
        error
    fi
    if [ $TEST_PLANNED = -1 ]; then
        diag "Tests were run but done_testing() was not seen."
        error
    fi
    [ $TEST_PLANNED = $TEST_COUNT -a $TEST_FAILS = 0 ] && exit 0
    if [ $TEST_COUNT != $TEST_PLANNED ]; then
        diag "Looks like you planned $TEST_PLANNED test(s) but ran $TEST_COUNT."
    fi
    if [ $TEST_FAILS -gt 0 ]; then
        diag "Looks like you failed $TEST_FAILS test(s) of $TEST_COUNT."
    fi
    [ $TEST_FAILS -gt 254 ] && TEST_FAILS=254
    exit $TEST_FAILS
}

error() {
    [ $# = 1 ] && echo "$1" >&2
    exit 255
}

# Usage: match SUBSTR STRING
#
# Returns true if SUBSTR is found in STRING, false otherwise.
match() { [ "${2%"$1"*}" != "$2" ]; }

# Usage: varname VARNAME
#
# Returns true if VARNAME is a valid shell variable name, false otherwise. (A
# variable name may only consist of alphanumeric characters and underscores,
# and the first character may not be a number. Also it may not consist of the
# empty string, or a single "_".)
varname() {
    case "$1" in ""|_|[0-9]*|*[!a-zA-Z0-9_]*) return 1; esac
    return 0
}

# Usage: strip_newline VARNAME
#
# Strip one trailing newline in VARNAME, or, if there is no trailing newline,
# appends the string "\No newline at end".
#
# This is intended to prettify string for output (in 'fail' or similar) while
# still having a predictable result (as opposed to the shell's builtin $(...)
# which strips any number of trailing newlines).
strip_newline() {
    [ $# != 1 ]  && error "strip_newline: Too many args"
    varname "$1" || error "strip_newline: Bad VARNAME '$1'"
    eval 'set $1 "$'$1'" "
"'  # $1 = variable name / $2 = variable content / $3 = newline
    if [ "${2%$3}" = "$2" ]; then
        eval $1'="$2\\No newline at end"'
    else
        eval $1'="${2%$3}"'
    fi
}

# Usage: indent PROMPT [MSG] [<<EOF
#            CONTENT
#        EOF]
#
# Output MSG, then CONTENT on standard output, after indenting them with PROMPT
# follow by a single space. Prefix is output as-is on the first line, each
# subsequent line is indented by as many spaces as there are characters in the
# original PROMPT.
#
# If there is no output and PROMPT contains non-space characters, then a single
# PROMPT is outputted on a line all by itself.
indent() {
    local PROMPT="$1" MSG="$2" SHOWN="" INDENT="" LINE=""
    case "$PROMPT" in
        *[!' ']*) : ;;
        *)  SHOWN=1                            # PROMPT consists of only spaces
            INDENT="$PROMPT"
    esac
    if [ -n "$MSG" ]; then
        echo "$MSG" | indent "$PROMPT"
        SHOWN=1
    fi
    if [ ! -t 0 ]; then                        # input on stdin
        while IFS='' read -r LINE; do
            if [ -z "$SHOWN" ]; then           # 1st line (has prompt)
                echo "$PROMPT${LINE:+ $LINE}"
                SHOWN=1
                continue
            fi
            if [ -z "$INDENT" ]; then
                INDENT="$(echo "$PROMPT"|tr "[:graph:]" " ")"
            fi
            echo "${LINE:+$INDENT $LINE}"
        done
    fi
    [ -z "$SHOWN" ] && echo "$PROMPT"          # make sure PROMPT was shown
}

done_testing() {
    if [ $TEST_PLANNED = -1 ]; then
        echo "1..$TEST_COUNT"
        TEST_PLANNED=$TEST_COUNT
        return 0
    fi
    fail "done_testing() already called"
}

skip_all() {
    local REASON="$1"
    if [ $TEST_PLANNED = -1 ]; then
        echo "1..0 # SKIP $REASON"
    else
        echo "skip_all() called after done_testing()" >&2
    fi
    exit $TEST_FAILS
}

# Usage: $(descr MODE [DESCR])
#
# Returns the test description DESCR, and if there is a string defined for the
# specified test MODE, appends that as well. E.g. if the test is running in
# SKIP mode, and 'descr' was called as 'descr SKIP "Return value"' then descr
# will return "Return value # SKIP <REASON>" (see also SKIP/END_SKIP and
# TODO/END_TODO).
descr() {
    local MODE="$1" DESCR="$2" REASON=""
    [ "$MODE" = TODO -o "$MODE" = SKIP ] || error "descr: Bad MODE '$MODE'"
    eval 'REASON="$TEST_'$1'"'
    case "$REASON" in
        "") echo "$DESCR" ;;
        .)  echo "${DESCR:+$DESCR }# $MODE" ;;
        *)  echo "${DESCR:+$DESCR }# $MODE $REASON" ;;
    esac
}

# Usage: TODO [REASON]
#        ...              # tests
#        [END_TODO]
#
# Marks the following tests as TODO, optionally providing a REASON (to be
# displayed in the test output). -- TODO tests are used for features which you
# have not yet implemented, but which you plan to add later on (features on
# your TODO list).
#
# These TODO test are expected to FAIL and therefore, to avoid cluttering up
# the output, no detailed diagnostics will we shown (just a single 'not ok'
# line per test).
#
# A good TAP test runner (e.g. the prove(1) command that comes with Perl) will
# notify you if any of your TODO tests suddenly start passing (which most
# likely mean that you have implemented the related feature and that you should
# now turn the test in question into a regular, non-TODO test).
#
# NOTE: Another way of marking a test as TODO is to append "# TODO [<REASON>]"
# to its test name. (This is might be more convenient if you need to mark a
# single test as TODO.)
TODO() {
    [ $# -gt 1 ] && error "TODO: Too many args"
    TEST_TODO="${1:-.}"
}

# Usage: END_TODO
#
# Turn off TODO mode. Takes no arguments.
END_TODO() {
    [ $# = 0 ] || error "END_TODO: No args allowed"
    TEST_TODO=""
}

SKIP() {
    [ $# -gt 1 ] && error "SKIP: Too many args"
    TEST_SKIP="${1:-.}"
}

END_SKIP() {
    [ $# = 0 ] || error "END_SKIP: No args allowed"
    TEST_SKIP=""
}

BAIL_OUT() {
    echo "Bail out!${1:+ $1}"
    error
}

# Usage: diag [MSG] [<<EOF
#            CONTENT
#        EOF]
#
# Prints a diagnostic message which is guaranteed not to interfere with test
# output. Returns false, so that you may use 'fail || diag', and still have a
# false return value.
#
# Diagnostic messages are printed on stderr, and always displayed when using
# 'prove' (and other test harnesses), so use them sparingly. See also 'note'.
#
# If MSG and CONTENT are both given, MSG will be output first, then CONTENT.
diag() {
    note "$@" >&2
    return 1
}

# Usage: note [MSG] [<<EOF
#            CONTENT
#        EOF]
#
# Prints debug message which will only be seen when running 'prove' (or other
# test harness) in verbose mode ('prove -v') or when running the test script
# manually. Handy for putting in notes which might be useful for debugging, but
# which do not indicate a problem. See also 'diag'.
#
# If MSG and CONTENT are both given, MSG will be output first, then CONTENT.
note() {
    local MSG="$1"
    [ -n "$MSG" ] && echo "$MSG" | note
    [ -t 0 ] && return
    while IFS='' read -r MSG; do
        echo "#${MSG:+ $MSG}"
    done
}

# Usage: result RESULT [DESCR]
#
# Outputs RESULT (which must be either 'ok' or 'not ok'), followed by the test
# counter and test description DESCR (if any). The test counter as also
# automatically increased.
result() {
    local RESULT="$1" DESCR="$2"
    TEST_COUNT="$(( TEST_COUNT + 1 ))"
    case "$DESCR" in
        "")  echo "$RESULT $TEST_COUNT" ;;
        \#*) echo "$RESULT $TEST_COUNT $DESCR" ;;
        *)   echo "$RESULT $TEST_COUNT - $DESCR" ;;
    esac
}

# Usage: pass [DESCR] [MSG]
#
# Call this for each passing test. Outputs the TAP protocol 'ok' line for the
# test together with the test description DESCR (if any). If message MSG is
# provided, it will be outputted after the 'ok' line in such a fashion that it
# will only be visible if you're running your test harness in 'verbose' mode
# (just as if you would've called 'note' just after 'pass').
pass() {
    local DESCR="$(descr TODO "$1")" MSG="$2"
    result "ok" "$DESCR"
    note "$MSG"
    return 0
}

# Usage: pass [DESCR] [MSG]
#
# Call this for each failing test. Ouptuts the TAP protocol 'not ok' line for
# the test together with the test description DESCR (if any). If message MSG is
# provided it will be outputted as a diagnostic message to the user and care
# should be taken to make MSG as informative as possible. MSG is (like 'diag'
# messages) always displayed (regardless of whether the test harness is in
# 'verbose' mode or not).
fail() {
    local DESCR="$(descr TODO "$1")" MSG="$2"
    result "not ok" "$DESCR"
    match "# TODO" "$DESCR" && return 0        # no diagnostics for TODO tests
    TEST_FAILS=$(( TEST_FAILS + 1 ))
    # Insert extra newline when piped (so 'prove' output looks ok).
    # (Skip this if we're bailing out after the failure.)
    [ -n "$BAIL_ON_FAIL" -o -t 1 ] || echo >&2
    if [ -z "$DESCR" ]; then
        diag <<-EOF
	  Failed test in '$0'
	EOF
    else
        diag <<-EOF
	  Failed test '$DESCR'
	  in '$0'
	EOF
    fi
    indent "   " "$MSG" | diag                 # diagnostic message + stdin
    [ -n "$BAIL_ON_FAIL" ] && BAIL_OUT
    [ -n  "$DIE_ON_FAIL" ] && error
    return 1
}

ok() {
    local EXPR="$*" DESCR="" ERRMSG="" RESULT=""
    for DESCR; do :; done                      # get last arg
    [ "$DESCR" = "]" ] && DESCR=""             #   unset DESCR if ']'
    EXPR="${EXPR% $DESCR}"                     #   EXPR = all but DESCR
    if [ -n "${EXPR%\[*}" ]; then              # must start & have only one '['
        error "ok: Error in args: 'missing or multiple ['"
    fi
    ERRMSG="$(eval "$EXPR 2>&1")"; RESULT=$?
    if [ -n "$ERRMSG" ]; then                  # error msg from eval
        error "ok: Error in args: '${ERRMSG#* \[: }'"
    fi
    if [ $RESULT = 0 ]; then
        pass "$DESCR"
        return
    fi
    fail "$DESCR" <<-EOF
	Expression should evaluate to true, but it isn't
	$EXPR
	EOF
}

# Usage: setread VARNAME [+] [<FILE]
#    or: setread VARNAME [+] [<<EOF
#            CONTENT
#        EOF]
#
# Read a FILE (or the CONTENT of a here document) and capture the contents in
# VARNAME (if no input is given it will be set to empty string before
# processing trailing newlines). If '+' is given as a second argument trailing
# newlines are preserved as-is, otherwise the very last newline is stripped (if
# final character is not a newline, the string '\No newline at end' is
# appended).
#
# The handling of trailing newlines differs from the shell contstruct $(...)
# which strips ALL trailing newlines. 'setread' is intentionally more
# restrictive since the strings are used in string comparison tests.
#
#     setread X   <<-EOF               # set X to "hello"
#         hello
#         EOF
#     setread X + <<-EOF               # set X to "hello" + newline
#         hello
#         EOF
#
# NOTA BENE: Piping into 'setread' DOES NOT WORK. (E.g. 'echo text|setread X'.)
# -- This is because the shell executes each process of a pipe in its own
# subshell, and all variables set by these processes are simply wiped as the
# processes exit.
setread() {
    # NOTA BENE: This function use only positional parameters ($1, $2, etc) no
    # ordinary vars. This avoids namespace collision between local vars and
    # VARNAME. (If local vars were used, and user one of those used in function
    # it could not be set globally.)
    [ $# -gt 2 ] && error "setread: Too many args"
    varname "$1" || error "setread: Bad VARNAME '$1'"
    [ "$2" != "+" ] && set "$1" ""             # $2 is '+' or ''
    if [ ! -t 0 ]; then
        set $1 "$2" "$(while IFS="" read -r L; do echo "$L"; done; echo "$L.")"
    fi
    eval $1'="${3%.}"'
    [ -z "$2" ] && strip_newline $1
}

# Usage: seteval VARNAME [+] STATEMENTS
#
# Evaluates shell STATEMENTS and capture the output thereof into the variable
# named VARNAME. Normally the very last newline is stripped, but if '+' is
# given as the second argument no stripping is done at all. (This differs from
# the '$(...)' construct which strips all trailing newlines.) If no newline was
# could be stripped then the string '\No newline at end' is appended instead
# (see also: 'setread').
#
#     seteval X   'echo hello'         # set X to "hello"
#     seteval X + 'echo hello'         # set X to "hello" + newline
seteval() {
    # NOTA BENE: This function use only positional parameters ($1, $2, etc) no
    # ordinary vars. This avoids namespace collision between local vars and
    # VARNAME. (If local vars were used, and user one of those used in function
    # it could not be set globally.)
    [ $# -gt 3 ] && error "seteval: Too many args"
    varname "$1" || error "seteval: Bad VARNAME '$1'"
    [ "$2" != "+" ] && set "$1" "" "$2"        # $2 is '+' or ''
    set  $1 "$2" "$(eval "$3"; echo .)"
    eval $1'="${3%.}"'
    [ -z "$2" ] && strip_newline $1
}

##############################################################################
##                                                                          ##
##  Test Functions                                                          ##
##                                                                          ##
##############################################################################

##
## Below are test functions, intended to be used it test scripts.
##

##
## WRITING NEW TEST FUNCTIONS
## ==========================
##
## Skipping of Tests
## -----------------
## User can skip tests in one of two ways: Either by enabling skip mode (using
## the SKIP and END_SKIP functions), or by adding "# SKIP <REASON>" to the
## description of an individual test. A skipped test is not run, but always
## report "ok" in the TAP output.
##
## For this to work each individual test function must check to see if it
## should be skipped. This is done by:
##
##     1. Appending SKIP mode string (if set) to the test description
##     2. Immediately passing if the test description contain '# SKIP'
##
## The code look like this:
##
##     local ... DESCR="$(descr SKIP "$3")"
##     match "# SKIP" "$DESCR" && pass "$DESCR" && return
##
## 'TODO' mode is handed in a similar fashion, but by the 'fail' and 'pass'
## functions, so this need not be handled by the individual test functions.
##
## Passing/Failing of Tests
## ------------------------
## Each test function should end in either calling 'pass' or 'fail'. Both of
## these functions take a description, plus an extra diagnostic message as
## argument (though the diagnostic message is seldom needed with the 'pass'
## function).
##

is() {
    local GOT="$1" WANTED="$2" DESCR="$(descr SKIP "$3")" NL="
"   # NB: intentional newline
    match "# SKIP" "$DESCR" && pass "$DESCR" && return
    [ $# -gt 3 ] && error "is: Too many args"
    if [ "$GOT" = "$WANTED" ]; then
        pass "$DESCR"
        return
    fi
    seteval GOT    'indent "GOT   :" "$GOT"'
    seteval WANTED 'indent "WANTED:" "$WANTED"'
    fail "$DESCR" <<-EOF
	$GOT
	$WANTED
	EOF
}

file_is() {
    local FILE="$1" WANTED="$2" DESCR="$(descr SKIP "$3")"
    match "# SKIP" "$DESCR" && pass "$DESCR" && return
    # FIXME: don't ignore trailing newlines
    local GOT="$(cat "$FILE")"
    is "$GOT" "$WANTED" "$DESCR"
}

file_exist() {
    local FILE="$1" DESCR="$(descr SKIP "$2")"
    match "# SKIP" "$DESCR" && pass "$DESCR" && return
    if [ -e "$FILE" ]; then
        pass "$DESCR"
        return
    fi
    fail "$DESCR" <<-EOF
	File '$FILE' should exist, but it does not
	EOF
}

file_not_exist() {
    local FILE="$1" DESCR="$(descr SKIP "$2")"
    match "# SKIP" "$DESCR" && pass "$DESCR" && return
    if [ ! -e "$FILE" ]; then
        pass "$DESCR"
        return
    fi
    fail "$DESCR" <<-EOF
	File '$FILE' should not exist, but it does
	EOF
}

# Usage: TIMESTAMP="$(timestamp FILE)"
#
# Stats FILE to get a timestamp (for passing on to is_unchanged, later).
timestamp() {
    local FILE="$1"
    if [ -e "$FILE" ]; then
        local SHA="$(sha1sum "$FILE")"
        echo "${SHA%% *} $(ls --full-time "$FILE")"
    else
        echo "<NON-EXISTING FILE> $FILE"
    fi
}

# Usage: is_changed TIMESTAMP
#
# Compares TIMESTAMP with the file from which the TIMESTAMP was originally
# gotten, return false if the files mtime or other metadata have been modified
# TIMESTAMP was obtained, true if it has not changed.
is_changed() {
    local OLD_TIMESTAMP="$1" DESCR="$(descr SKIP "$2")"
    match "# SKIP" "$DESCR" && pass "$DESCR" && return
    local FILE="${OLD_TIMESTAMP##* }"
    local NEW_TIMESTAMP="$(timestamp "$FILE")"
    if [ "$NEW_TIMESTAMP" != "$OLD_TIMESTAMP" ]; then
        pass "$DESCR"
        return
    fi
    seteval OLD_TIMESTAMP 'indent OLD: "$OLD_TIMESTAMP"'
    seteval NEW_TIMESTAMP 'indent NEW: "$NEW_TIMESTAMP"'
    fail "$DESCR" <<-EOF
	File '$FILE' has been modified, but it shouldn't have
	$OLD_TIMESTAMP
	$NEW_TIMESTAMP
	EOF
}

# Usage: is_unchanged TIMESTAMP
#
# Compares TIMESTAMP with the file from which the TIMESTAMP was originally
# gotten, return false if the files mtime or other metadata have been modified
# TIMESTAMP was obtained, true if it has not changed.
is_unchanged() {
    local OLD_TIMESTAMP="$1" DESCR="$(descr SKIP "$2")"
    match "# SKIP" "$DESCR" && pass "$DESCR" && return
    local FILE="${OLD_TIMESTAMP##* }"
    local NEW_TIMESTAMP="$(timestamp "$FILE")"
    if [ "$NEW_TIMESTAMP" = "$OLD_TIMESTAMP" ]; then
        pass "$DESCR"
        return
    fi
    seteval OLD_TIMESTAMP 'indent OLD: "$OLD_TIMESTAMP"'
    seteval NEW_TIMESTAMP 'indent NEW: "$NEW_TIMESTAMP"'
    fail "$DESCR" <<-EOF
	File '$FILE' has been modified, but it shouldn't have
	$OLD_TIMESTAMP
	$NEW_TIMESTAMP
	EOF
}

##############################################################################
##                                                                          ##
##  Test Initialization                                                     ##
##                                                                          ##
##############################################################################

##
## These functions are specific for the fix.sh tests. They are used to set up
## a test case before running it, and do not perform any actual testing.
##

# Usage: init_test [DIR...]
#
# Initializes a tempdir, and changes directory to it. If any DIR(s) are
# specified they will be created inside the tempdir (relative paths will be
# interpreted relative to the tempdir).
#
# If there is a directory (or symlink) called the same thing as the test file
# (but without the '.t' extension) that directory is taken to contain a '.fix'
# state dir, which is then copied to '.fix' in the tempdir.
#
# Also sets the TESTCMD variable to the full path of 'fix.sh' (it should be
# used in tests instead of refering to any literal executable).
init_test() {
    readonly TESTCMD="$PWD/fix.sh"
    local TESTFILE="$PWD/$0" TESTDIR="$PWD/${0%.t}"
    local TMPDIR="$(mktemp -dt "fix-test-${TESTDIR##*/}.XXXXXX")"
    cd "$TMPDIR"
    note "DIR: $TMPDIR"
    [ $# -gt 0 ] && mkdir -p "$@"
    [ -e "$TESTDIR" ] && cp -rH "$TESTDIR" .fix
}

# Usage: execute CMD TRAPFILE
#    or: execute <<EOF TRAPFILE
#            CMD
#        EOF
#
# Evals CMD in a subshell, saving to TRAPFILE whether the command(s) exited
# ('EXIT'), or ran all the way through ('FULL'). This can be used to invoke a
# function and see whether it called return ('FULL') or exit ('EXIT').
#
# Exit status will be the same as the exit status of the terminating command in
# CMD (if 'exit' was called, this is be whatever exit status was specified with
# 'exit').
execute() {
    local CMD="$1" TRAPFILE="$2"
    if [ ! -t 0 ]; then
        TRAPFILE="$1"
        setread CMD +
    fi
    [ -z "$TRAPFILE" ] && error "execute: Missing TRAPFILE arg"
    (
        trap "echo EXIT >\"$TRAPFILE\"; trap - 0" 0
        eval "$CMD"
        STATUS=$?
        trap - 0
        echo FULL >"$TRAPFILE"
        exit $STATUS
    )
}

mkpath() {
    local DIR="${1%/*}"                        # strip trailing filename
    [ -d "$DIR" ] || mkdir -p -- "$DIR"
}

# Usage: chtime YYYY-MM-DD FILE
#
# Change mtime of FILE to YYYY-MM-DD.
chtime() {
    local TIME="$1" FILE="$2"
    [ -e "$FILE" ] || error "chtime: file '$FILE' not found"
    if [ "${TIME#+}" != "${TIME#-}" ]; then    # plus/minus time
        touch -r"$FILE" -d"$TIME" "$FILE" \
            || error "chtime: cannot set file '$FILE' time to '$TIME'"
        return
    fi
    TIME="$(echo "$TIME"|tr -d -)0000"
    touch -t"$TIME" "$FILE" || error "chtime: 'touch' cannot update '$FILE'"
}

# Usage: write_file [BITS] [TIME] FILE [<<EOF
#            CONTENT
#        EOF]
#
# Creates FILE and writes CONTENT to it (if no CONTENT is give then a zero byte
# file is written), thereafter, for the arguments specified, touch(1) the FILE
# to set its mtime to TIME, and chmod(1) it to set its permissions to BITS.
#
# The last argument as always taken to be FILE, TIME and BITS can come in any
# order and is recognized by their syntax. TIME is one of:
#
#   * YYYY-MM-DD
#   * string starting with '+' or '-', follow by digit and ending in letter
#     (e.g. '-1second' or '+1 month') see info page for touch(1) '-d' option
#     for more info (unfortunately manpage is only rudimentary)
#
# BITS is one of:
#
#   * 3 octal digits (e.g. '755', '644')
#   * anything that contains '-', '+' or '=' followed by one of 'rwxXstugo'
#     (this may optionally be preceeded or followed by other letters, making
#     all of the normal chmod(1) arguments available, e.g. 'a-r', 'u+x', '-w'
#     etc.)
#
write_file() {
    local DATE="" BITS="" FILE="" LINE=""
    while :; do
        [ $# = 1 ] && { FILE="$1"; break; }
        case "$1" in
            [-+][0-9]*[a-z]|????-??-??)
                [ -n "$DATE" ] && error "write_file: Too many DATE args"
                DATE="$1" ;;
            *[-+=][rwxXstugo]*|[0-7][0-7][0-7])
                [ -n "$BITS" ] && error "write_file: Too many BITS args"
                BITS="$1" ;;
            *) error "write_file: Bad arg '$1'"
        esac
        shift
    done
    mkpath "$FILE" 2>/dev/null \
        || error "write_file: Cannot create dir for file '$FILE'"
    {
        [ -t 0 ] || while IFS='' read -r LINE; do
            echo "$LINE"
        done
    } >"$FILE"
    [ -n "$BITS" ] && chmod  "$BITS" "$FILE"
    [ -n "$DATE" ] && chtime "$DATE" "$FILE"
}

#[eof]
