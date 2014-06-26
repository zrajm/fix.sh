#!/usr/bin/env dash

##############################################################################
##                                                                          ##
##  Functions                                                               ##
##                                                                          ##
##############################################################################

error() {
    echo "ERROR: $1" >&2
    [ "$2" ] && echo "    ($2)" >&2
    exit 1
}

build() {
    local SCRIPT="$FIX_SCRIPT_DIR/$1.fix"
    local TARGET="$FIX_TARGET_DIR/$1"
    local TARGET_DIR="${TARGET%/*}"
    local TARGET_TMP="$TARGET--fixing"

    # check preconditions
    [ -e "$SCRIPT" ] || error "build script '$SCRIPT' does not exist"
    [ -x "$SCRIPT" ] || error "build script '$SCRIPT' is not executable"

    # run buildscript
    [ -e "$TARGET_DIR" ] || mkdir -p -- "$TARGET_DIR"
    "$SCRIPT" >"$TARGET_TMP" <&-
    local STATUS=$?                            # check buildscript exit status
    if [ $STATUS -ne 0 ]; then
        error "build script '$SCRIPT' returned exit status $STATUS" \
            "Target unmodified; script output can be found in '$TARGET_TMP'."
    fi
    # new target is same as old target, keep old as-is
    if diff "$TARGET" "$TARGET_TMP" >/dev/null; then
        rm -f -- "$TARGET_TMP"
        return
    fi
    # new target is different than old target, keep new
    mv -f -- "$TARGET_TMP" "$TARGET"
}

##############################################################################
##                                                                          ##
##  Init                                                                    ##
##                                                                          ##
##############################################################################

if [ ! "$FIX" ]; then                          # mother process
    export FIX="$(readlink -f $0)"
    export FIX_LEVEL=0
    export FIX_PID=$$
    export FIX_DIR="$PWD/.fix"
    export FIX_SCRIPT_DIR="fix"
    export FIX_SOURCE_DIR="src"
    export FIX_TARGET_DIR="build"
    [ -d "$FIX_SOURCE_DIR" ] || error "source dir '$FIX_SOURCE_DIR' does not exist"
    [ -d "$FIX_SCRIPT_DIR" ] || error "script dir '$FIX_SCRIPT_DIR' does not exist"
else                                           # child
    FIX_LEVEL=$(( FIX_LEVEL + 1 ))
fi

##############################################################################
##                                                                          ##
##  Main                                                                    ##
##                                                                          ##
##############################################################################

while [ $# -gt 0 ]; do                         # for each argument
    build $1
    shift
done

#[eof]
