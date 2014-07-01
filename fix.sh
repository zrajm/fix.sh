#!/usr/bin/env dash

# May be set by user:
#   * FIX_DEBUG
#   * FIX_FORCE

##############################################################################
##                                                                          ##
##  Functions                                                               ##
##                                                                          ##
##############################################################################

debug() {
    [ "$FIX_DEBUG" ] && echo "$1" >&2
}

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

run() {
    local CMD="$1" STATUS=0

    # check build script
    [ -e "$CMD" ] || error "Build script '$CMD' does not exist"
    [ -r "$CMD" ] || error "No read permission for build script '$CMD'"
    [ -x "$CMD" ] || error "No execute permission for build script '$CMD'"

    # run buildscript
    "$CMD"
    STATUS=$?                                  # check buildscript exit status
    if [ $STATUS -ne 0 ]; then
        error "Build script '$CMD' returned exit status $STATUS" \
            "Old target unchanged. New, failed target written to '$TARGET_TMP'."
    fi
}

store_result() {
    local DBFILE="$1" TARGET="$2" TARGET_TMP="$3"

    local META_CHECKSUM="$(meta_checksum "$DBFILE")"
    local OLD_CHECKSUM="$(file_checksum "$TARGET")"
    local NEW_CHECKSUM="$(file_checksum "$TARGET_TMP")"

    # update target
    if [ ! -e "$TARGET" ]; then
        debug "$TARGET: No previous target, write new target"
        mv -f -- "$TARGET_TMP" "$TARGET"
    elif [ "$NEW_CHECKSUM" = "$OLD_CHECKSUM" ]; then
        debug "$TARGET: Target unchanged, keep old target"
        rm -f -- "$TARGET_TMP"
    elif [ -e "$DBFILE" -a "$OLD_CHECKSUM" = "$META_CHECKSUM" ]; then
        debug "$TARGET: Target updated, write new target"
        mv -f -- "$TARGET_TMP" "$TARGET"
    elif [ "$FIX_FORCE" ]; then
        debug "$TARGET: Target updated + external change, forced overwrite"
        mv -f -- "$TARGET_TMP" "$TARGET"
    else
        error "Old target '$TARGET' modified by user, won't overwrite" \
            "Erase old target before rebuild. New target kept in '$TARGET_TMP'."
    fi

    # update metadata
    if [ "$NEW_CHECKSUM" != "$META_CHECKSUM" ]; then
        mkpath "$DBFILE" || error "Cannot create dir for metadata file '$DBFILE'"
        debug "$TARGET: Writing metadata"
        echo "$NEW_CHECKSUM $TARGET" >"$DBFILE"
    else
        debug "$TARGET: Metadata is up-to-date"
    fi
}

build() {
    local DBFILE="$FIX_DIR/$1"
    local SCRIPT="$FIX_SCRIPT_DIR/$1.fix"
    local TARGET="$FIX_TARGET_DIR/$1"
    mkpath "$TARGET" || error "Cannot create dir for target '$TARGET'"
    run "$SCRIPT" >"$TARGET--fixing" <&-
    store_result "$DBFILE" "$TARGET" "$TARGET--fixing"
}


##############################################################################
##                                                                          ##
##  Init                                                                    ##
##                                                                          ##
##############################################################################

if [ ! "$FIX" ]; then                          # mother process
    # FIX_FORCE FIX_DEBUG
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
