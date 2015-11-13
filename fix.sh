#!/usr/bin/env dash

# May be set by user:
#   * FIX_DEBUG
#   * FIX_FORCE
#   * FIX_SOURCE

# FIX_PARENT and FIX_METADATA is set for all child invocations.

set -ue

##############################################################################
##                                                                          ##
##  Functions                                                               ##
##                                                                          ##
##############################################################################

debug() {
    [ "$FIX_DEBUG" ] && echo "$1" >&2
    return 0
}

die() {
    local STATUS="$1" MSG="$2" EXTRA="${3:-}"
    echo "ERROR: $MSG" >&2
    [ "$EXTRA" ] && echo "    ($EXTRA)" >&2
    is_mother || kill "$PPID"                  # kill parent buildscript
    exit "$STATUS"
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

# Return true if this Fix process was invoked from command line, false if it
# was invoked from a buildscript.
is_mother() {
    [ "$FIX_LEVEL" -eq 0 ]
}

establish_lock() {
    local LOCKFILE="$1" SIG
    mkpath "$LOCKFILE" || die 7 "Cannot create dir for lockfile '$LOCKFILE'"
    ({ set -o noclobber; echo "$$" >"$LOCKFILE"; } 2>/dev/null) || return 1
    trap "rm -f '$LOCKFILE'" EXIT
    for SIG in HUP INT TERM; do
        # remove lockfile, then re-kill myself without trapping the signal
        trap "rm -f '$LOCKFILE'; trap -- EXIT $SIG; kill -$SIG $$" "$SIG"
    done
}

# Run buildscript, write tempfile. React to exit status.
build_run() {
    local CMD="$1" TARGET="$2" TMPFILE="$3"
    [ -e "$CMD" ] || die 1 "Buildscript '$CMD' does not exist"
    [ -r "$CMD" ] || die 1 "No read permission for buildscript '$CMD'"
    [ -x "$CMD" ] || die 1 "No execute permission for buildscript '$CMD'"

    # FIXME: Catch a failure to write to $TMPFILE
    "$CMD" >"$TMPFILE" <&- &                   # run buildscript
    wait "$!" || die 1 "Buildscript '$CMD' returned exit status $?" \
        "Old target unchanged. New, failed target written to '$TMPFILE'."
}

# After build: Overwrite target with tempfile, and store result in metadata.
build_finalize() {
    local DBFILE="$1" TYPE="$2" TARGET="$3" TARGET_TMP="$4"
    local META_CHECKSUM="$(meta_checksum "$DBFILE")"
    local OLD_CHECKSUM="$(file_checksum "$TARGET")"
    local NEW_CHECKSUM="$(file_checksum "$TARGET_TMP")"
    local FILE=""

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
        die 1 "Old target '$TARGET' modified by user, won't overwrite" \
            "Erase old target before rebuild. New target kept in '$TARGET_TMP'."
    fi

    # update metadata
    if [ "$NEW_CHECKSUM" != "$META_CHECKSUM" ]; then
        mkpath "$DBFILE" \
            || die 7 "Cannot create dir for metadata file '$DBFILE'"
        debug "$TARGET: Writing metadata"

        case "$TYPE" in
            SCRIPT) FILE="${SCRIPT#$FIX_SCRIPT_DIR/}" ;;
            SOURCE) FILE="${SOURCE#$FIX_SOURCE_DIR/}" ;;
            TARGET) FILE="${TARGET#$FIX_TARGET_DIR/}" ;;
            *) die 30 "build_finalize: Failed to write metadata" \
                "Internal error: unknown type '$TYPE' for file '$TARGET'" ;;
        esac
        echo "$NEW_CHECKSUM $TYPE $FILE" >"$DBFILE"
    else
        debug "$TARGET: Metadata is up-to-date"
    fi
}

build() {
    local DBFILE="$FIX_DIR/state/$1" \
        SCRIPT="$FIX_SCRIPT_DIR/$1.fix" \
        TARGET="$FIX_TARGET_DIR/$1"
    mkpath "$TARGET" || die 6 "Cannot create dir for target '$TARGET'"
    build_run "$SCRIPT" "$TARGET" "$TARGET--fixing"
    build_finalize "$DBFILE" TARGET "$TARGET" "$TARGET--fixing"
}

##############################################################################
##                                                                          ##
##  Init                                                                    ##
##                                                                          ##
##############################################################################

: ${FIX_DEBUG:=""}                             # --debug  (default off)
: ${FIX_FORCE:=""}                             # --force  (default off)
: ${FIX_SOURCE:=""}                            # --source (default off)
: ${FIX_TARGET:=""}
: ${FIX_LEVEL:=-1}                             # 0 = ran from command line
FIX_LEVEL="$(( FIX_LEVEL + 1 ))"               #   +1 for each invokation
FIX_PARENT="$FIX_TARGET"

[ "$#" = 0 ] && die 15 "No target(s) specified"
if is_mother; then                             # mother process
    export FIX_LEVEL FIX_PARENT FIX_TARGET
    export FIX="$(readlink -f "$0")"
    export FIX_PID="$$"
    export FIX_DIR=".fix"
    export FIX_LOCK="$FIX_DIR/lock.pid"
    export FIX_SCRIPT_DIR="fix"
    export FIX_SOURCE_DIR="src"
    export FIX_TARGET_DIR="build"
    [ -n "$FIX_SOURCE" ] \
        && die 15 "Option '--source' can only be used inside buildscript"
    [ -d "$FIX_SOURCE_DIR" ] \
        || die 10 "Source dir '$FIX_SOURCE_DIR' does not exist"
    [ -d "$FIX_SCRIPT_DIR" ] \
        || die 10 "Script dir '$FIX_SCRIPT_DIR' does not exist"
    establish_lock "$FIX_LOCK" \
        || die 8 "Cannot create lockfile '$FIX_LOCK'" \
        "Is ${FIX##*/} is already running? Is lockfile dir writeable?"
fi

##############################################################################
##                                                                          ##
##  Main                                                                    ##
##                                                                          ##
##############################################################################

for TARGET; do
    if [ "$FIX_SOURCE" ]; then
        # register $TARGET as dependency to parent
        :
    else
        FIX_TARGET="$TARGET"
        build "$TARGET"
    fi
done

#[eof]
