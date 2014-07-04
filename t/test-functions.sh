# -*- sh -*-

##############################################################################
##                                                                          ##
##  Test Functions                                                          ##
##                                                                          ##
##############################################################################

TEST_COUNT=0
TEST_FAIL_COUNT=0
TEST_PLAN_COUNT=''

trap 'on_exit; trap - 0' 0                     # exit messages
on_exit() {
    if [ "$TEST_COUNT" = 0 ]; then
        diag "No tests run!"
        exit 255
    fi
    if [ -z "$TEST_PLAN_COUNT" ]; then
        diag "Tests were run but done_testing() was not seen."
        exit 255
    fi
    [ $TEST_PLAN_COUNT = $TEST_COUNT -a $TEST_FAIL_COUNT = 0 ] && exit 0
    if [ $TEST_COUNT != $TEST_PLAN_COUNT ]; then
        diag "Looks like you planned $TEST_PLAN_COUNT test(s) but ran $TEST_COUNT."
    fi
    if [ $TEST_FAIL_COUNT -gt 0 ]; then
        diag "Looks like you failed $TEST_FAIL_COUNT test(s) of $TEST_COUNT."
    fi
    [ $TEST_FAIL_COUNT -gt 254 ] && TEST_FAIL_COUNT=254
    exit $TEST_FAIL_COUNT
}

done_testing() {
    if [ -z "$TEST_PLAN_COUNT" ]; then
        echo "1..$TEST_COUNT"
        TEST_PLAN_COUNT=$TEST_COUNT
        return 0
    fi
    fail "done_testing() already called"
}

skip_all() {
    local REASON="$1"
    if [ -n "$TEST_PLAN_COUNT" ]; then
        echo "skip_all() called after done_testing()" >&2
    fi
    if [ -z "$TEST_PLAN_COUNT" ]; then
        echo "1..0 # SKIP $REASON"
        #TEST_PLAN_COUNT=$TEST_COUNT
    fi
    exit $TEST_FAIL_COUNT
}

bail_out() {
    echo "Bail out!${1:+ $1}"
    trap - 0                                   # disable exit messages
    exit 255
}

diag() {
    note "$@" >&2
    # Returns false, so that 'fail || diag' will return false.
    return 1
}

note() {
    [ -n "$*" ] && echo "# $*"
    [ -t 0 ] && return
    local LINE
    while IFS='' read -r LINE; do
        echo "#${LINE:+ $LINE}"
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
    TEST_FAIL_COUNT=$(( TEST_FAIL_COUNT + 1 ))
    result "not ok" "$NAME"; shift
    # Insert extra newline when piped (so 'prove' output looks ok).
    [ -t 1 ] || echo >&2
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
    return 1
}

is() {
    local GOT="$1" EXPECTED="$2" NAME="$3"
    if [ "$GOT" = "$EXPECTED" ]; then
        pass "$NAME"
        return
    fi
    fail "$NAME" <<-EOF
	    GOT     : '$GOT'
	    EXPECTED: '$EXPECTED'
	EOF
}

file_is() {
    local GOT_FILE="$1" EXPECTED="$2" NAME="$3"
    local GOT="$(cat "$GOT_FILE")"
    is "$GOT" "$EXPECTED" "$NAME"
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
    note "File '$FILE' has been modified, but it shouldn't have"
    note "  Old timestamp: '$OLD_TIMESTAMP'"
    note "  New timestamp: '$NEW_TIMESTAMP'"
}

#[eof]
