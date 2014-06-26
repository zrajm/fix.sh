#!/usr/bin/env dash

# May be set by user:
#   * FIX_FORCE

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

mkpath() {
    local DIR="${1%/*}"                        # strip trailing filename
    [ -d "$DIR" ] || mkdir -p -- "$DIR"
}

meta_checksum() {
    local FILE="$1" CHECKSUM=""
    [ -e "$FILE" ] && read CHECKSUM <"$FILE"
    echo "${CHECKSUM%% *}"                     # checksum without filename
}

file_checksum() {
    local FILE="$1" CHECKSUM=""
    [ -e "$FILE" ] && CHECKSUM="$(sha1sum "$FILE")"
    echo "${CHECKSUM%% *}"                     # checksum without filename
}

build() {
    local DBFILE="$FIX_DIR/$1"
    local SCRIPT="$FIX_SCRIPT_DIR/$1.fix"
    local TARGET="$FIX_TARGET_DIR/$1"
    local TARGET_TMP="$TARGET--fixing"
    local STATUS=0 STORED_CHECKSUM=""
    local OLD_TARGET_CHECKSUM="" NEW_TARGET_CHECKSUM=""

    # check build script
    [ -e "$SCRIPT" ] || error "Build script '$SCRIPT' does not exist"
    [ -x "$SCRIPT" ] || error "Build script '$SCRIPT' is not executable"

    # run buildscript
    mkpath "$TARGET" || error "Can't create dir for target '$TARGET'"
    "$SCRIPT" >"$TARGET_TMP" <&-
    STATUS=$?                                  # check buildscript exit status
    if [ $STATUS -ne 0 ]; then
        error "Build script '$SCRIPT' returned exit status $STATUS" \
            "Old target unchanged. New, failed target written to '$TARGET_TMP'."
    fi

    STORED_CHECKSUM="$(meta_checksum "$DBFILE")"
    OLD_TARGET_CHECKSUM="$(file_checksum "$TARGET")"
    NEW_TARGET_CHECKSUM="$(file_checksum "$TARGET_TMP")"

    if [ "$OLD_TARGET_CHECKSUM" = "$NEW_TARGET_CHECKSUM" ]; then
        rm -f -- "$TARGET_TMP"                 # new is same as old
    elif [ "$FIX_FORCE" -o ! -e "$TARGET" \
        -o "$OLD_TARGET_CHECKSUM" = "$STORED_CHECKSUM" ]; then
        mv -f -- "$TARGET_TMP" "$TARGET"       # old written by fix or no old
    else
        error "Old target '$TARGET' modified by user, won't overwrite" \
            "Erase old target before rebuild. New target kept in '$TARGET_TMP'."
    fi

    # metadata unchanged
    [ "$NEW_TARGET_CHECKSUM" = "$STORED_CHECKSUM" ] && return

    mkpath "$DBFILE" || error "can't create dir for buildstat file '$DBFILE'"
    echo "$NEW_TARGET_CHECKSUM $TARGET" >"$DBFILE"
    return
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
    export FIX_DIR=".fix"
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
