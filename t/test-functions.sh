# -*- sh -*-

##
## ENVIRONMENT VARIABLE OPTIONS
## ----------------------------
## Set these variables to a non-empty string to get the described effect.
## (Variable names are chosen to be compatible with Test::Most.)
##
##   * BAIL_ON_FAIL - abort on first test fail
##   *  DIE_ON_FAIL - skip remaining tests in file when test fail
##

##############################################################################
##                                                                          ##
##  Test Functions                                                          ##
##                                                                          ##
##############################################################################

TEST_COUNT=0                                   # tests performed
TEST_FAILS=0                                   # failed tests
TEST_PLANNED=-1                                # plan (set by done_testing)
trap 'on_exit; trap - 0' 0                     # exit messages
on_exit() {
    if [ $TEST_COUNT = 0 ]; then
        diag "No tests run!"
        exit 255
    fi
    if [ $TEST_PLANNED = -1 ]; then
        diag "Tests were run but done_testing() was not seen."
        exit 255
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

BAIL_OUT() {
    echo "Bail out!${1:+ $1}"
    exit 255
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

result() {
    local MSG="$1" NAME="$2"
    TEST_COUNT="$(( TEST_COUNT + 1 ))"
    echo "$MSG $TEST_COUNT${NAME:+ - $NAME}"
}

pass() {
    local NAME="$1"; shift
    result "ok" "$NAME"
    note "$@"
    return 0
}

fail() {
    local NAME="$1" MSG="$2"
    TEST_FAILS=$(( TEST_FAILS + 1 ))
    result "not ok" "$NAME"
    # Insert extra newline when piped (so 'prove' output looks ok).
    # (Skip this if we're bailing out after the failure.)
    [ -n "$BAIL_ON_FAIL" -o -t 1 ] || echo >&2
    if [ -z "$NAME" ]; then
        diag <<-EOF
	  Failed test in '$0'
	EOF
    else
        diag <<-EOF
	  Failed test '$NAME'
	  in '$0'
	EOF
    fi
    indent "   " "$MSG" | diag                 # diagnostic message + stdin
    [ -n "$BAIL_ON_FAIL" ] && BAIL_OUT
    [ -n  "$DIE_ON_FAIL" ] && exit 255
    return 1
}

ok() {
    local EXPR="$*" NAME="" ERRMSG="" RESULT=""
    for NAME; do :; done                       # get last arg
    [ "$NAME" = "]" ] && NAME=""               #   ignore if ']'
    EXPR="${EXPR% $NAME}"                      #   strip last arg
    if [ -n "${EXPR%\[*}" ]; then              # must start & have only one '['
        echo "ok: Error in expression: 'missing or multiple ['" >&2
        return 255
    fi
    ERRMSG="$(eval "$EXPR 2>&1")"; RESULT=$?
    if [ -n "$ERRMSG" ]; then                  # error msg from eval
        echo "ok: Error in expression: '${ERRMSG#* \[: }'" >&2
        return 255
    fi
    if [ $RESULT = 0 ]; then
        pass "$NAME"
        return
    fi
    fail "$NAME" <<-EOF
	Expression should be true, but it isn't
	$EXPR
	EOF
}

is() {
    local GOT="$1" WANTED="$2" NAME="$3"
    if [ "$GOT" = "$WANTED" ]; then
        pass "$NAME"
        return
    fi
    fail "$NAME" <<-EOF
	$(indent "GOT   :" "$GOT")
	$(indent "WANTED:" "$WANTED")
	EOF
}

file_is() {
    local FILE="$1" WANTED="$2" NAME="$3"
    local GOT="$(cat "$FILE")"
    is "$GOT" "$WANTED" "$NAME"
}

file_exist() {
    local FILE="$1" NAME="$2"
    if [ -e "$FILE" ]; then
        pass "$NAME"
        return
    fi
    fail "$NAME" <<-EOF
	File '$FILE' should exist, but it does not
	EOF
}

file_not_exist() {
    local FILE="$1" NAME="$2"
    if [ ! -e "$FILE" ]; then
        pass "$NAME"
        return
    fi
    fail "$NAME" <<-EOF
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

# Usage: is_unchanged TIMESTAMP
#
# Compares TIMESTAMP with the file from which the TIMESTAMP was originally
# gotten, return false if the files mtime or other metadata have been modified
# TIMESTAMP was obtained, true if it has not changed.
is_unchanged() {
    local OLD_TIMESTAMP="$1" NAME="$2"
    local FILE="${OLD_TIMESTAMP##* }"
    local NEW_TIMESTAMP="$(timestamp "$FILE")"
    if [ "$NEW_TIMESTAMP" = "$OLD_TIMESTAMP" ]; then
        pass "$NAME"
        return
    fi
    fail "$NAME" <<-EOF
	File '$FILE' has been modified, but it shouldn't have
	$(indent "OLD:" "$OLD_TIMESTAMP")
	$(indent "NEW:" "$NEW_TIMESTAMP")
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

mkpath() {
    local DIR="${1%/*}"                        # strip trailing filename
    [ -d "$DIR" ] || mkdir -p -- "$DIR"
}

# Usage: chtime YYYY-MM-DD FILE
#
# Change mtime of FILE to YYYY-MM-DD.
chtime() {
    local DATE="$(echo "$1"|tr -d -)0000" FILE="$2"
    touch -t"$DATE" "$FILE" || {
        echo "chtime: 'touch' failed to update '$FILE'" >&2
        exit 255
    }
}

# Usage: write_file FILE [YYYY-MM-DD] [BITS] [<<EOF
#            CONTENT
#        EOF]
#
# Creates FILE and writes CONTENT (if no CONTENT is give on standard input,
# then a zero byte file is created), thereafter chmod(1)s FILE to set file
# permissions to BITS, and touch(1)es to set its mtime to YYYY-MM-DD (if any of
# those are specified).
write_file() {
    local FILE="$1" DATE="" BITS="" LINE=""; shift
    for LINE; do
        case "$1" in
            ????-??-??) DATE="$1" ;;
            *[a-z])     BITS="$1" ;;
            *) echo "write_file: bad arg '$LINE'" >&2; exit 255 ;;
        esac; shift
    done
    mkpath "$FILE"
    if [ -t 0 ]; then
        : >"$FILE"
    else
        while IFS='' read -r LINE; do
            echo "$LINE"
        done >"$FILE"
    fi
    [ -n "$BITS" ] && chmod  "$BITS" "$FILE"
    [ -n "$DATE" ] && chtime "$DATE" "$FILE"
}

#[eof]
