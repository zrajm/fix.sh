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
##    call 'pass' or 'fail') in a pipe, the global $DASHTAP_COUNT variable
##    can't be updated, meaning that your test count will not agree with the
##    number of 'ok'/'not ok' messages in your TAP output. The following code
##    is therefore also (subtly) broken:
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

dashtap_init() {
    DASHTAP_COUNT=0                            # tests performed
    DASHTAP_FAILS=0                            # failed tests
    DASHTAP_PLANNED=-1                         # plan (set by done_testing)
    DASHTAP_TITLE=""                           # test title (if any)
    DASHTAP_TODO=""                            # TODO reason (if any)
    DASHTAP_SKIP=""                            # SKIP reason (if any)
    DASHTAP_FILE="$PWD/$0"                     # name of script file
    DASHTAP_DIR="${DASHTAP_FILE%.t}"           # data dir for script
    trap 'dashtap_exit; trap - 0' 0            # exit messages
}
dashtap_init
dashtap_exit() {
    [ -z "$DASHTAP_COUNT" ] && error "result: 'dashtap_init' was never called"
    if [ "$DASHTAP_COUNT" = 0 ]; then
        diag "No tests run!"
        error
    fi
    if [ "$DASHTAP_PLANNED" = -1 ]; then
        diag "Tests were run but done_testing() was not seen."
        error
    fi
    [ "$DASHTAP_PLANNED" = "$DASHTAP_COUNT" -a "$DASHTAP_FAILS" = 0 ] && exit 0
    if [ "$DASHTAP_COUNT" != "$DASHTAP_PLANNED" ]; then
        diag "Looks like you planned $DASHTAP_PLANNED test(s) but ran $DASHTAP_COUNT."
    fi
    if [ "$DASHTAP_FAILS" -gt 0 ]; then
        diag "Looks like you failed $DASHTAP_FAILS test(s) of $DASHTAP_COUNT."
    fi
    [ "$DASHTAP_FAILS" -gt 254 ] && DASHTAP_FAILS=254
    exit "$DASHTAP_FAILS"
}

error() {
    [ $# = 1 ] && echo "$1" >&2
    exit 255
}

# Usage: match SUBSTR STRING
#    or: echo STRING | match SUBSTR
#
# Returns true if SUBSTR could be found in STRING, false otherwise. If STRING
# is not given as a second argument, reads standard input and searches that
# instead.
match() {
    local SUBSTR="$1" STR="$2"
    if [ $# = 1 ]; then                        # one arg = read stdin
        STR=""; setread + STR
    elif [ $# != 2 ]; then
        error "match: Bad number of args"
    fi
    [ "${STR%"$SUBSTR"*}" != "$STR" ]
}

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
    [ $# = 1   ] || error "strip_newline: Bad number of args"
    varname "$1" || error "strip_newline: Bad VARNAME '$1'"
    eval 'set $1 "$'$1'" "
"'  # $1 = variable name / $2 = variable content / $3 = newline
    if [ "${2%$3}" = "$2" ]; then
        eval $1'="$2\\No newline at end"'
    else
        eval $1'="${2%$3}"'
    fi
}

# Usage: indent PROMPT [MSG] [<<-"EOF"
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
    if [ "$DASHTAP_PLANNED" = -1 ]; then
        echo "1..$DASHTAP_COUNT"
        DASHTAP_PLANNED="$DASHTAP_COUNT"
        return 0
    fi
    fail "done_testing() already called"
}

skip_all() {
    local REASON="$1"
    if [ "$DASHTAP_PLANNED" = -1 ]; then
        echo "1..0 # SKIP $REASON"
    else
        echo "skip_all() called after done_testing()" >&2
    fi
    exit "$DASHTAP_FAILS"
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
    eval 'REASON="$DASHTAP_'$1'"'
    case "$REASON" in
        "") echo "$DESCR" ;;
        .)  echo "${DESCR:+$DESCR }# $MODE" ;;
        *)  echo "${DESCR:+$DESCR }# $MODE $REASON" ;;
    esac
}

# Usage: title TITLE
#    or: title - <<-"EOF"
#            TITLE
#        EOF
#
# Set TITLE for subsequent tests, to unset title use 'end_title' (very rarely
# needed).
#
# If set, TITLE is included in the diagnostics output of the first failing test
# (which is always visible if one or more tests fail), and in the debug output
# at the point where 'title' was called (which is visible only if the test
# harness is in verbose mode).
title() {
    [ $# = 1 ] || error "title: Bad number of args"
    if [ "$1" = "-" ]; then
        setread DASHTAP_TITLE
    else
        DASHTAP_TITLE="$1"
    fi
    note "$DASHTAP_TITLE"
}

end_title() {
    [ $# = 0 ] || error "end_title: No args allowed"
    DASHTAP_TITLE=""
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
    DASHTAP_TODO="${1:-.}"
}

# Usage: END_TODO
#
# Turn off TODO mode. Takes no arguments.
END_TODO() {
    [ $# = 0 ] || error "END_TODO: No args allowed"
    DASHTAP_TODO=""
}

SKIP() {
    [ $# -gt 1 ] && error "SKIP: Too many args"
    DASHTAP_SKIP="${1:-.}"
}

END_SKIP() {
    [ $# = 0 ] || error "END_SKIP: No args allowed"
    DASHTAP_SKIP=""
}

BAIL_OUT() {
    echo "Bail out!${1:+ $1}"
    error
}

# Usage: diag [MSG] [<<-"EOF"
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

# Usage: note [MSG] [<<-"EOF"
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
    [ -z "$DASHTAP_COUNT" ] && error "result: 'dashtap_init' was never called"
    DASHTAP_COUNT="$(( DASHTAP_COUNT + 1 ))"
    case "$DESCR" in
        "")  echo "$RESULT $DASHTAP_COUNT" ;;
        \#*) echo "$RESULT $DASHTAP_COUNT $DESCR" ;;
        *)   echo "$RESULT $DASHTAP_COUNT - $DESCR" ;;
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
    # Insert one extra newline before the first error when piped (this makes
    # 'prove' output look ok). -- Not needed if we're bailing out after the
    # failure.
    [ -z "$BAIL_ON_FAIL" -a "$DASHTAP_FAILS" = 0 -a ! -t 1 ] && echo >&2
    DASHTAP_FAILS="$(( DASHTAP_FAILS + 1 ))"
    if [ -n "$DASHTAP_TITLE" ]; then
        diag "$DASHTAP_TITLE" <&-
        DASHTAP_TITLE=""
    fi
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

# Usage: VARNAME="$(stdin)"             # to truncate trailing newlines
#    or: VARNAME="$(stdin; echo .)"     # to preserve trailing newlines
#        VARNAME="${VARNAME%.}"
#
# Reads all of standard input and outputs it on standard output. Intended for
# use instead of cat in $(...) constructs. Don't forget take precautions if you
# want to preserve trailing newlines!
stdin() {
    local LINE=""
    [ -t 0 ] || while IFS="" read -r LINE; do
        echo "$LINE"
    done
    printf "%s" "$LINE"
}

# Usage: setread [+] VARNAME CONTENT
#    or: setread [+] VARNAME [<FILE]
#    or: setread [+] VARNAME <<-"EOF"
#            CONTENT
#        EOF
#
# Read a FILE (or the CONTENT of a here document) and capture the contents in
# VARNAME (if no input is given it will be set to empty string before
# processing trailing newlines). If '+' is given as the first argument trailing
# newlines are preserved as-is, otherwise the very last newline is stripped (if
# final character is not a newline, the string '\No newline at end' is
# appended).
#
# The handling of trailing newlines differs from the shell contstruct $(...)
# which strips ALL trailing newlines. 'setread' is intentionally more
# restrictive since the strings are used in string comparison tests.
#
#     setread   X <<-"EOF"             # set X to "hello"
#         hello
#         EOF
#     setread + X <<-"EOF"             # set X to "hello" + newline
#         hello
#         EOF
#
# NOTA BENE: A function may read its own standard input with setread but
# otherwise stuff piping into 'setread' DOES NOT WORK (e.g. 'echo text|setread
# X'). This is because the shell executes each process of a pipe in its own
# subshell, and all variables set by these processes are simply wiped as the
# processes exit.
setread() {
    # NOTA BENE: This function use only positional parameters ($1, $2, etc) no
    # ordinary vars. This avoids namespace collision between local vars and
    # VARNAME. (If local vars were used, and user one of those used in function
    # it could not be set globally.)
    [ "$1" != "+" ] && set -- "" "$@"          # $1 is '+' or ''
    [ $# -lt 2 -o $# -gt 3 ] && error "setread: Bad number of args"
    varname "$2" || error "setread: Bad VARNAME '$2'"
    if [ $# = 3 ]; then                        # set to $3
        eval $2'="$3"'
    else                                       # set to STDIN
        set -- "$@" "$(stdin; echo .)"
        eval $2'="${3%.}"'
    fi
    [ -z "$1" ] && strip_newline $2
}

# Usage: seteval [+] VARNAME STATEMENTS
#    or: seteval [+] VARNAME [<FILE]
#    or: seteval [+] VARNAME <<-"EOF"
#            STATEMENTS
#        EOF
#
# Evaluates shell STATEMENTS and capture standard output thereof into the
# variable named VARNAME. Normally the very last newline is stripped, but if
# '+' is given as the second argument no stripping is done at all. (This
# differs from the '$(...)' construct which strips all trailing newlines.) If
# no newline was could be stripped then the string '\No newline at end' is
# appended instead (see also: 'setread').
#
# The return value will be the same as the one returned by the evaluated code.
#
#     seteval   X 'echo hello'         # set X to "hello"
#     seteval + X 'echo hello'         # set X to "hello" + newline
seteval() {
    # NOTA BENE: This function use only positional parameters ($1, $2, etc) no
    # ordinary vars. This avoids namespace collision between local vars and
    # VARNAME. (If local vars were used, and user one of those used in function
    # it could not be set globally.)
    [ "$1" != "+" ] && set -- "" "$@"          # $1 is '+' or ''
    [ $# -lt 2 -o $# -gt 3 ] && error "seteval: Bad number of args"
    varname "$2" || error "seteval: Bad VARNAME '$2'"
    [ $# = 2 ] && set -- "$@" "$(stdin)"        # read STDIN
    set -- "$1" "$2" "$(eval "$3"; echo ":$?")" # append return value
    eval $2'="${3%:*}"'
    [ -z "$1" ] && strip_newline $2
    return "${3##*:}"
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

# Usage: is GOT WANTED [DESCRIPTION]
is() {
    [ $# = 2 -o $# = 3 ] || error "is: Bad number of args"
    local GOT="$1" WANTED="$2" DESCR="$(descr SKIP "$3")"
    match "# SKIP" "$DESCR" && pass "$DESCR" && return
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

# Usage: isnt GOT WANTED [DESCRIPTION]
isnt() {
    [ $# = 2 -o $# = 3 ] || error "isnt: Bad number of args"
    local GOT="$1" WANTED="$2" DESCR="$(descr SKIP "$3")"
    match "# SKIP" "$DESCR" && pass "$DESCR" && return
    if [ "$GOT" != "$WANTED" ]; then
        pass "$DESCR"
        return
    fi
    seteval GOT    'indent "GOT   :" "$GOT"'
    seteval WANTED 'indent "WANTED:" "anything else"'
    fail "$DESCR" <<-EOF
	$GOT
	$WANTED
	EOF
}

# Usage: function_exists FUNCTION [DESCRIPTION]
function_exists() {
    [ $# = 1 -o $# = 2 ] || error "function_exists: Bad number of args"
    local FUNCTION="$1" DESCR="$(descr SKIP "$2")"
    match "# SKIP" "$DESCR" && pass "$DESCR" && return
    if type "$FUNCTION" | match "function"; then
        pass "$DESCR"
        return
    fi
    fail "$DESCR" <<-EOF
	Function '$FUNCTION' should exist, but it does not
	EOF
}

# Usage: file_is FILE WANTED [DESCRIPTION]
file_is() {
    [ $# = 2 -o $# = 3 ] || error "file_is: Bad number of args"
    local FILE="$1" WANTED="$2" DESCR="$(descr SKIP "$3")" GOT=""
    match "# SKIP" "$DESCR" && pass "$DESCR" && return
    if [ -r "$FILE" ]; then
        setread GOT <"$FILE"
        is "$GOT" "$WANTED" "$DESCR"
    else
        fail "$DESCR" <<-EOF
		File '$FILE' should be readable, but it is not
		EOF
    fi
}

# Usage: file_exists FILE [DESCRIPTION]
file_exists() {
    [ $# = 1 -o $# = 2 ] || error "file_exists: Bad number of args"
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

# Usage: file_not_exists FILE [DESCRIPTION]
file_not_exists() {
    [ $# = 1 -o $# = 2 ] || error "file_not_exists: Bad number of args"
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

# Usage: timestamp TIMESTAMP FILE
#
# Collects TIMESTAMP from FILE. TIMESTAMP contains info on the current state if
# FILE, and can later be passed to 'is_changed' or 'is_unchanged' to see if the
# file has schanged since 'timestamp' wass called.
#
# See also: 'timestamp_file' and 'timestamp_time'.
timestamp() {
    [ $# != 2  ] && error "timestamp_time: Bad number of args"
    varname "$1" || error "settimestamp: Bad VARNAME '$1'"
    if [ -e "$2" ]; then
        # $1 = VARNAME; $2 = FILE; $3 = SHA; $4 = 'ls' output
        set -- "$@" "$(sha1sum "$2")" "$(ls -l --time-style="+[%s.%N]" "$2")"
        eval $1'="${3%% *} $4"'
    else
        eval $1'="[NON-EXISTING FILE] $1"'
    fi
}

# Usage: timestamp_file VARNAME TIMESTAMP
#
# Sets VARNAME to the filename found in TIMESTAMP.
timestamp_file() {
    [ $# != 2  ] && error "timestamp_file: Bad number of args"
    varname "$1" || error "timestamp_file: Bad VARNAME '$1'"
    set -- "$1" "$2" "${2#*\] }"
    [ "$2" = "$3" ] && error "timestamp_file: Bad TIMESTAMP '$TIMESTAMP'"
    eval $1'="$3"'
}

# Usage: timestamp_mtime VARNAME TIMESTAMP
#
# Sets VARNAME to the mtime found in TIMESTAMP. Time is expressed in the
# traditional Unix epoch format (i.e. seconds since midnight 1970-01-01) plus
# nanoseconds (which will be all zeroes if your file system only have second
# resolution).
timestamp_time() {
    [ $# != 2  ] && error "timestamp_file: Bad number of args"
    varname "$1" || error "timestamp_file: Bad VARNAME '$1'"
    set -- "$1" "$2" "${2#*\[}"
    set -- "$1" "$2" "${3%%\] *}"
    [ "$2" = "$3" ] && error "timestamp_time: Bad TIMESTAMP '$2'"
    eval $1'="$3"'
}

# Usage: reset_timestamp TIMESTAMP
#
# Resets the file mtime of the file in TIMESTAMP, so that the new mtime of that
# file becomes the same as when TIMESTAMP was originally collected.
reset_timestamp() {
    [ $# != 1 ] && error "reset_timestamp: Bad number of args"
    local TIMESTAMP="$1" FILE TIME
    timestamp_file FILE "$TIMESTAMP"
    timestamp_time TIME "$TIMESTAMP"
    case "$TIME" in
        "NON-EXISTING FILE") : ;;
        *[!0-9.]*|*.*.*)
            error "reset_timestamp: Bad time in '$TIMESTAMP'" ;;
        *)  [ -e "$FILE" ] \
                || error "reset_timestamp: File does not exist in '$TIMESTAMP'"
            touch -d "@$TIME" "$FILE" ;;
    esac
}

# Usage: is_changed TIMESTAMP [DESCRIPTION]
#
# Compares TIMESTAMP with the file from which the TIMESTAMP was originally
# gotten, return false if the files mtime or other metadata have been modified
# TIMESTAMP was obtained, true if it has not changed.
is_changed() {
    [ $# = 1 -o $# = 2 ] || error "is_changed: Bad number of args"
    local OLD_TIMESTAMP="$1" DESCR="$(descr SKIP "$2")" FILE NEW_TIMESTAMP
    match "# SKIP" "$DESCR" && pass "$DESCR" && return
    timestamp_file FILE "$OLD_TIMESTAMP"
    if [ -e "$FILE" ]; then
        timestamp NEW_TIMESTAMP "$FILE"
        if [ "$NEW_TIMESTAMP" != "$OLD_TIMESTAMP" ]; then
            pass "$DESCR"
        else
            seteval OLD_TIMESTAMP 'indent OLD: "$OLD_TIMESTAMP"'
            seteval NEW_TIMESTAMP 'indent NEW: "$NEW_TIMESTAMP"'
            fail "$DESCR" <<-EOF
		File '$FILE' has been modified, but it shouldn't have
		$OLD_TIMESTAMP
		$NEW_TIMESTAMP
		EOF
        fi
    else
        fail "$DESCR" <<-EOF
		File '$FILE' should exist, but it does not
		EOF
    fi
}

# Usage: is_unchanged TIMESTAMP [DESCRIPTION]
#
# Compares TIMESTAMP with the file from which the TIMESTAMP was originally
# gotten, return false if the files mtime or other metadata have been modified
# TIMESTAMP was obtained, true if it has not changed.
is_unchanged() {
    [ $# = 1 -o $# = 2 ] || error "is_unchanged: Bad number of args"
    local OLD_TIMESTAMP="$1" DESCR="$(descr SKIP "$2")" FILE NEW_TIMESTAMP
    match "# SKIP" "$DESCR" && pass "$DESCR" && return
    timestamp_file FILE "$OLD_TIMESTAMP"
    if [ -e "$FILE" ]; then
        timestamp NEW_TIMESTAMP "$FILE"
        if [ "$NEW_TIMESTAMP" = "$OLD_TIMESTAMP" ]; then
            pass "$DESCR"
        else
            seteval OLD_TIMESTAMP 'indent OLD: "$OLD_TIMESTAMP"'
            seteval NEW_TIMESTAMP 'indent NEW: "$NEW_TIMESTAMP"'
            fail "$DESCR" <<-EOF
		File '$FILE' has been modified, but it shouldn't have
		$OLD_TIMESTAMP
		$NEW_TIMESTAMP
		EOF
        fi
    else
        fail "$DESCR" <<-EOF
		File '$FILE' should exist, but it does not
		EOF
    fi
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
    NADA=""; strip_newline NADA                # NADA = '\No newline at end'
    readonly TESTCMD="$PWD/fix.sh" NADA
    local TMPDIR="$(mktemp -dt "fix-test-${DASHTAP_DIR##*/}.XXXXXX")"
    cd "$TMPDIR"
    note "DIR: $TMPDIR"
}

# Usage: cpdir DIR...
#
# Copies the specified DIR(s) from the data directory of the current dashtap
# script, to it execution directory (tempdir).
cpdir() {
    for DIR; do
        DIR="$DASHTAP_DIR/$DIR"
        [ -e "$DIR" ] && cp -a "$DIR" .
    done
}

# Usage: execute COMMAND TRAPFILE
#    or: execute TRAPFILE <<-"EOF"
#            COMMAND
#        EOF
#
# Eval shell COMMAND(s) in a subshell, saving to FILE whether the command(s)
# ran all the way through ('ALL') or exited before that ('SOME'). This can be
# used to invoke a function and see whether it called exit ('SOME') or return
# ('ALL').
#
# Return status will be the same as the exit status of the terminating command
# in COMMAND (if COMMANDS were terminated with 'exit', the return code will be
# the same as the exit status).
execute() {
    local CMD="$1" TRAPFILE="$2"
    if [ $# = 1 ]; then                        # one arg = read stdin
        TRAPFILE="$1"
        CMD=""; setread + CMD
    elif [ $# != 2 ]; then
        error "execute: Bad number of args"
    fi
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
    if [ "${TIME#+}" != "${TIME#-}" ]; then    # time starts with '+' or '-'
        touch -r"$FILE" -d"$TIME" "$FILE" \
            || error "chtime: cannot set file '$FILE' time to '$TIME'"
        return
    fi
    TIME="$(echo "$TIME"|tr -d -)0000"
    touch -t"$TIME" "$FILE" || error "chtime: 'touch' cannot update '$FILE'"
}

# Usage: write_file [BITS] [TIME] FILE [<<-"EOF"
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
    local DATE="" BITS="" FILE="" CONTENT=""
    while [ $# -gt 1 ]; do
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
    FILE="$1"
    mkpath "$FILE" 2>/dev/null \
        || error "write_file: Can't create dir for file '$FILE'"
    setread + CONTENT
    printf "%s" "$CONTENT" >"$FILE"
    [ -n "$BITS" ] && chmod  "$BITS" "$FILE"
    [ -n "$DATE" ] && chtime "$DATE" "$FILE"
}

#[eof]
