#!/usr/bin/env dash
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]

set -ue
VERSION=0.11.8

##############################################################################
##                                                                          ##
##  Functions                                                               ##
##                                                                          ##
##############################################################################

echo() { printf "%s\n" "$@"; }                 # safe 'echo'
cat() {                                        # 'cat' using shell builtins
    [ -t 0 ] && die "cat: Missing input on stdin"
    local TXT
    while IFS="" read -r TXT; do               # last line must end in <LF>
        echo "$TXT"
    done
}
reverse() {                                    # reverse lines of a file
    local FILE="$1" TXT; shift
    while IFS="" read -r TXT; do               # last line must end in <LF>
        set -- "$TXT" "$@"
    done <"$FILE"
    echo "$@" >"$FILE"
}

usage() {
    cat <<END_USAGE
Usage: ${0##*/} [OPTION]... TARGET...
Build TARGET(s) based on which dependencies has changed.

Options:
  -D, --debug    enable debug mode (extra output on standard error)
  -f, --force    overwrite target files modified by user
  -h, --help     display this information and exit
      --source   declare source dependency (only allowed in buildscripts)
  -V, --version  output version information and exit

END_USAGE
    exit
}

version() {
    cat <<END_VERSION
fix.sh (Fix) $VERSION
Copyright (C) 2015 zrajm <fix@zrajm.org>
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

For the latest version of Fix, see <https://github.com/zrajm/fix.sh>.
END_VERSION
    exit
}

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

# Usage: save_metadata STATEFILE ( TYPE:FILE CHECKSUM )...
#
# Saves build metadata to STATEFILE. The two last arguments may be repeated to
# save multiple lines to STATEFILE.
save_metadata() {
    local STATEFILE="$1" DEPFILE CHECKSUM; shift
    mkpath "$STATEFILE" \
        || die 7 "Cannot create dir for metadata file '$STATEFILE'"
    while [ "$#" -ge 2 ]; do
        DEPFILE="$1"; CHECKSUM="$2"; shift 2
        printf "%s %s\n" "$CHECKSUM" "$DEPFILE"
    done >>"$STATEFILE"
    [ "$#" -eq 0 ] || die 7 "save_metadata: Bad number of args"
}

# Usage: load_metadata STATEFILE TYPE:FILE
#
# Outputs checksum of specified TYPE:FILE as read from STATEFILE. TYPE is a
# filename prefix, either 'SCRIPT', 'SOURCE' or 'TARGET'.
load_metadata() {
    local STATEFILE="$1" DEPFILE="$2" CHECKSUM2 DEPFILE2
    [ -e "$STATEFILE" ] && while IFS=" " read -r CHECKSUM2 DEPFILE2; do
        if [ "$DEPFILE2" = "$DEPFILE" ]; then
            echo "$CHECKSUM2"
            return 0
        fi
    done <"$STATEFILE"
    return 1
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

# Usage: add_fix_to_path DIR
#
# Creates DIR (which must be an absolute path), and puts a hardlink in DIR
# (called `fix`) linking to the currently running executable.
add_fix_to_path() {
    local DIR="$1" LINK="$1/fix" FIX="$(readlink -f "$0")"
    mkpath "$LINK" || die 7 "Cannot create dir for executable '$LINK'"
    ln -f "$FIX" "$LINK"
    PATH="$DIR:$PATH"
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
    "$CMD" >"$TMPFILE" "$TMPFILE" <&- &        # run buildscript
    wait "$!" || die 1 "Buildscript '$CMD' returned exit status $?" \
        "Old target unchanged. New, failed target written to '$TMPFILE'."
}

# Overwrite FILE with TMPFILE, if TMPFILE is different. Return true if FILE was
# overwritten, false otherwise.
finalize_tmpfile() {
    local TMPFILE="$1" FILE="$2" TMPFILE_CHECKSUM="$3" META_CHECKSUM="$4"
    local FILE_CHECKSUM="$(file_checksum "$FILE")"
    if [ ! -e "$FILE" ]; then
        debug "$FILE: No previous target, write new target"
    elif [ "$TMPFILE_CHECKSUM" = "$FILE_CHECKSUM" ]; then
        debug "$FILE: Target unchanged, keep old target"
        rm -f -- "$TMPFILE"
        return
    elif [ -e "$DBFILE" -a "$FILE_CHECKSUM" = "$META_CHECKSUM" ]; then
        debug "$FILE: Target updated, write new target"
    elif [ "$FIX_FORCE" ]; then
        debug "$FILE: Target updated + external change, forced overwrite"
    else
        die 1 "Old target '$FILE' modified by user, won't overwrite" \
            "Erase old target before rebuild. New target kept in '$TMPFILE'."
    fi
    mv -f -- "$TMPFILE" "$FILE"
}

# Usage: strip_path VAR TYPE FILE
#
# Where TYPE is 'SCRIPT', 'SOURCE' or 'TARGET'. Strip $FIX_[TYPE]_DIR off of
# FILE, and set VAR to the result.
strip_path() {
    case "$2" in
        SCRIPT|SOURCE|TARGET) :;;
        *) die 30 "strip_path: Unknown type '$2' for file '$3'"
            "Type must be 'SCRIPT', 'SOURCE' or 'TARGET'." ;;
    esac
    eval "$1=\"\$2:\${3#\$FIX_${2}_DIR/}\""
}

# After build: Overwrite target with tempfile, and store result in metadata.
build_finalize() {
    local DBFILE="$1" TYPE="$2" TARGET="$3" TARGET_TMP="$4" SCRIPT="$5"
    local TMP_CHECKSUM="$(file_checksum "$TARGET_TMP")"
    local FILE=""

    strip_path FILE "$TYPE" "$TARGET"

    # update target
    local OLD_CHECKSUM="$(load_metadata "$DBFILE" "$FILE")"
    finalize_tmpfile "$TARGET_TMP" "$TARGET" \
        "$TMP_CHECKSUM" "$OLD_CHECKSUM"

    # finalize metadata
    if [ "$FIX_PARENT" ]; then
        local DBPATH="${DBFILE%/*}"
        local DBFILE2="$DBPATH/$FIX_PARENT"
        save_metadata "$DBFILE2--fixing" "$FILE" "$TMP_CHECKSUM"
    fi

    # write to metadata tempfile
    local SCRIPT_CHECKSUM="$(file_checksum "$SCRIPT")"
    save_metadata "$DBFILE--fixing" \
        "SCRIPT:${SCRIPT#$FIX_SCRIPT_DIR/}" "$SCRIPT_CHECKSUM" \
        "$FILE"                             "$TMP_CHECKSUM"
    reverse "$DBFILE--fixing" \
        && mv -f -- "$DBFILE--fixing" "$DBFILE" >&2
}

build() {
    local DBFILE="$FIX_DIR/state/$1" \
        SCRIPT="$FIX_SCRIPT_DIR/$1.fix" \
        TARGET="$FIX_TARGET_DIR/$1"
    mkpath "$TARGET" || die 6 "Cannot create dir for target '$TARGET'"
    build_run "$SCRIPT" "$TARGET" "$TARGET--fixing"
    build_finalize "$DBFILE" TARGET "$TARGET" "$TARGET--fixing" "$SCRIPT"
}

##############################################################################
##                                                                          ##
##  Init                                                                    ##
##                                                                          ##
##############################################################################

# OPT_* variables are not exported.
# FIX_* variables are exported and inherited by child processes.
: ${FIX_DEBUG:=""}                             # --debug  (default off)
: ${FIX_FORCE:=""}                             # --force  (default off)
: ${FIX_TARGET:=""}
: ${FIX_LEVEL:=-1}                             # 0 = ran from command line
FIX_LEVEL="$(( FIX_LEVEL + 1 ))"               #   +1 for each invokation
FIX_PARENT="$FIX_TARGET"
OPT_SOURCE=""                                  # --source

COUNT="$#"
while [ "$COUNT" != 0 ]; do                    # read command line options
    ARG="$1"; shift; COUNT="$(( COUNT - 1 ))"
    case "$ARG" in
        -D|--debug) FIX_DEBUG=1  ;;
        -f|--force) FIX_FORCE=1  ;;
        -h|--help)  usage        ;;
        --source)   OPT_SOURCE=1 ;;
        -V|--version) version    ;;
        --) while [ "$COUNT" != 0 ]; do        #   put remaining args
                set -- "$@" "$1"               #     last in $@
                COUNT="$(( COUNT - 1 ))"
            done; break ;;                     #     and abort
        -*) die 15 "Unknown option '$ARG'" \
            "Try '$0 --help' for more information." ;;
        *)  set -- "$@" "$ARG" ;;              #   put non-option arg back
    esac
done
unset COUNT ARG

[ "$#" = 0 ] && die 15 "No target(s) specified"
if is_mother; then                             # mother process
    export FIX_DEBUG FIX_FORCE FIX_LEVEL FIX_PARENT FIX_TARGET
    export FIX_PID="$$"
    export FIX_DIR="$PWD/.fix"
    export FIX_LOCK="$FIX_DIR/lock.pid"
    export FIX_SCRIPT_DIR="$PWD/fix"
    export FIX_SOURCE_DIR="$PWD/src"
    export FIX_TARGET_DIR="$PWD/build"
    add_fix_to_path "$(readlink -f "$FIX_DIR")/bin"
    [ -n "$OPT_SOURCE" ] \
        && die 15 "Option '--source' can only be used inside buildscript"
    [ -d "$FIX_SOURCE_DIR" ] \
        || die 10 "Source dir '$FIX_SOURCE_DIR' does not exist"
    [ -d "$FIX_SCRIPT_DIR" ] \
        || die 10 "Script dir '$FIX_SCRIPT_DIR' does not exist"
    establish_lock "$FIX_LOCK" \
        || die 8 "Cannot create lockfile '$FIX_LOCK'" \
        "Is ${0##*/} is already running? Is lockfile dir writeable?"
fi

##############################################################################
##                                                                          ##
##  Main                                                                    ##
##                                                                          ##
##############################################################################

if [ "$OPT_SOURCE" ]; then
    for SOURCE; do
        FULL="$FIX_SOURCE_DIR/$SOURCE"
        [ -e "$FULL" ] || die 1 "Source file '$FULL' does not exist"
        [ -r "$FULL" ] || die 1 "No read permission for source file '$FULL'"
        DBFILE="$FIX_DIR/state/$FIX_PARENT"
        CHECKSUM="$(file_checksum "$FULL")"
        save_metadata "$DBFILE--fixing" "SOURCE:$SOURCE" "$CHECKSUM"
    done
else
    for TARGET; do
        FIX_TARGET="$TARGET"
        build "$TARGET"
    done
fi

#[eof]
