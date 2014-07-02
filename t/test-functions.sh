# -*- sh -*-

TEST_COUNT=0

# Increase test counter.
inc_test_count() {
    TEST_COUNT="$(( TEST_COUNT + 1 ))"
}
test_count() {
    echo $TEST_COUNT
}

# Output note.
note() {
    local LINE=''
    if [ -t 0 ]; then
        echo "# $*"
        return
    fi
    while read LINE; do
        echo "# $LINE"
    done
}

testout() {
    local MSG="$1"; shift
    local NAME="$*"
    inc_test_count
    if [ "$NAME" ]; then
        echo "$MSG $TEST_COUNT - $NAME"
    else
        echo "$MSG $TEST_COUNT"
    fi
}

success() {
    testout "ok" "$*"
}

failure() {
    testout "not ok" "$*"
}

has_exit_status() {
    local GOT="$?" EXPECTED="$1" NAME="$2"
    if [ "$GOT" = "$EXPECTED" ]; then
        success "$NAME"
        return
    fi
    failure "$NAME"
    note "Got exit status '$GOT', but expected '$EXPECTED'"
}

is() {
    local GOT="$1" EXPECTED="$2" NAME="$3"
    if [ "$GOT" = "$EXPECTED" ]; then
        success "$NAME"
        return
    fi
    failure "$NAME"
    cat <<-EOF | note
	  GOT      : '$GOT'
	  EXPECTED : '$EXPECTED'
	EOF
}

file_is() {
    local GOT_FILE="$1" EXPECTED="$2" NAME="$3"
    local GOT="$(cat "$GOT_FILE")"
    is "$GOT" "$EXPECTED" "$NAME"
}

# Output final test count.
done_testing() {
    echo "1..$TEST_COUNT"
}

#[eof]
