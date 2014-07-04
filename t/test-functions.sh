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

diag() {
    note "$@" >&2
    # Returns false, so that 'fail || diag' will return false.
    return 1
}

note() {
    local MSG="$*"
    [ -n "$MSG" ] && echo "# $MSG"
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
    local NAME="$1"
    TEST_FAILS=$(( TEST_FAILS + 1 ))
    result "not ok" "$NAME"; shift
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
    diag "$@"
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
    fail "$NAME" "    $EXPR is false"
}

is() {
    local GOT="$1" WANTED="$2" NAME="$3"
    if [ "$GOT" = "$WANTED" ]; then
        pass "$NAME"
        return
    fi
    fail "$NAME" <<-EOF
	    GOT   : '$GOT'
	    WANTED: '$WANTED'
	EOF
}

file_is() {
    local GOT_FILE="$1" WANTED="$2" NAME="$3"
    local GOT="$(cat "$GOT_FILE")"
    is "$GOT" "$WANTED" "$NAME"
}

file_exist() {
    local FILE="$1" NAME="$2"
    if [ -e "$FILE" ]; then
        pass "$NAME"
        return
    fi
    fail "$NAME" \
        "File '$FILE' should exist, but it doesn't"
}

file_not_exist() {
    local FILE="$1" NAME="$2"
    if [ ! -e "$FILE" ]; then
        pass "$NAME"
        return
    fi
    fail "$NAME" \
        "File '$FILE' shouldn't exist, but it does"
}

timestamp() {
    local FILE="$1"
    if [ -e "$FILE" ]; then
        ls --full-time "$FILE"
    else
        echo "<NON-EXISTING FILE> $FILE"
    fi
}

is_unchanged() {
    local OLD_TIMESTAMP="$1" FILE="$2" NAME="$3"
    local NEW_TIMESTAMP="$(timestamp "$FILE")"
    if [ "$NEW_TIMESTAMP" = "$OLD_TIMESTAMP" ]; then
        pass "$NAME"
        return
    fi
    fail "$NAME" <<-EOF
	    File '$FILE' has been modified, but it shouldn't have
	      Old timestamp: '$OLD_TIMESTAMP'
	      New timestamp: '$NEW_TIMESTAMP'
	EOF
}

#[eof]
