#!/usr/bin/env dash
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv3+ [https://github.com/zrajm/fix.sh/blob/master/LICENSE.txt]

set -eu
VERSION=0.11.30

##############################################################################
##                                                                          ##
##  Functions                                                               ##
##                                                                          ##
##############################################################################

say() { printf "%s\n" "$@"; }                  # safe 'echo'
read_stdin() {                                 # 'cat' using shell builtins
    [ -t 0 ] && die "read_stdin: Missing input on stdin"
    local TXT
    while IFS="" read -r TXT; do               # last line must end in <LF>
        say "$TXT"
    done
}
reverse_file() {                               # reverse lines of a file
    local FILE="$1" TXT; shift
    while IFS="" read -r TXT; do               # last line must end in <LF>
        set -- "$TXT" "$@"
    done <"$FILE"
    say "$@" >"$FILE"
}

usage() {
    read_stdin <<END_USAGE
Usage: ${0##*/} [OPTION]... TARGET...
Build TARGET(s) based on which dependencies has changed.

Options:
  -D, --debug    enable debug mode (extra output on standard error)
  -f, --force    overwrite target files modified by user
  -h, --help     display this information and exit
      --init     init metadata and set current dir as work tree root
      --source   declare source dependency (only allowed in buildscripts)
  -V, --version  output version information and exit

END_USAGE
    exit
}

version() {
    read_stdin <<END_VERSION
fix.sh (Fix) $VERSION
Copyright (C) 2015 zrajm <fix@zrajm.org>
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

For the latest version of Fix, see <https://github.com/zrajm/fix.sh>.
END_VERSION
    exit
}

init() {
    local FIX_DIR="$1"
    [ -e "$FIX_DIR" ]  && die 1 "Fix dir '%s' already exists" - "$FIX_DIR"
    mkpath "$FIX_DIR/" || die 1 "Cannot create fix dir '%s'"  - "$FIX_DIR"
    exit
}

debug() {
    [ "$FIX_DEBUG" ] && say "$1" >&2
    return 0
}

# Usage: die EXITCODE ERRMSG [ HELPMSG|- [FILE...] ]
#
# Display ERRMSG and exit Fix. If HELPMSG is provided it will displayed after
# ERRMSG indented and within parentheses (to give user suggestions about how to
# Fix the problem).
#
# You may put one or more printf sequences ('%s') into ERRMSG and HELPMSG to
# insert FILE name(s). The number of '%s' should be the same as the number of
# FILE arguments provided. FILE names included in this manner will (for brevity
# and clarity) be rewritten so that they are relative to user's current dir
# ($FIX_PWD) when being output.
#
# To provide one or more FILE(s), without specifying HELPMSG use '-' in place
# of HELPMSG.
die() {
    local STATUS="$1" MSG="$2" EXTRA="${3:-}" # FILE...
    shift "$(( $# < 3 ? $# : 3))"              # remove 1st three args from $@
    local FILE COUNT="$#"
    while [ "$COUNT" != 0 ]; do                # for each FILE arg
        setrun FILE relpath "$1" "${FIX_PWD:-$PWD}" # make filename relative
        shift; COUNT="$(( COUNT - 1 ))"
        set -- "$@" "${FILE#./}"
    done
    [ "$EXTRA" = "-" ] && EXTRA=""
    printf "ERROR: $MSG\n${EXTRA:+    ($EXTRA)\n}" "$@" >&2
    is_mother || kill "$PPID" 2>/dev/null ||:  # kill any parent buildscript
    exit "$STATUS"
}

# Usage: setrun VARIABLE COMMAND [ARG]...
#
# Execute COMMAND (with the ARG(s) provided), capture its standard output into
# VARIABLE and return with exit status of COMMAND. (Standard error is neither
# captured nor interferred with.)
setrun() {
    # NOTA BENE: Only positional parameters ($1, $2, etc) are used here. This
    # to avoid name collision with VARIABLE. (If named local vars were used
    # here, and user specified one of the same names as VARIABLE, that
    # variable's new content would not be visible outside this function.)
    case "$1" in ""|[0-9]*|*[!a-zA-Z0-9_]*)
        die 31 "setrun: Bad variable name '$1'"
    esac
    # $1=VARIABLE / $2=COMMAND output + ':' + exit code
    set -- "$1" "$(shift; set +e; "$@"; echo ":$?")" # run command
    # $1=VARIABLE / $2=COMMAND exit code / $3=COMMAND output / $4=<newline>
    set -- "$1" "${2##*:}" "${2%:*}" "
"
    eval "$1=\${3%\$4}"                        # strip one trailing newline
    return "$2"
}

# Usage: abspath [PATH [CWD]]
#
# Output the absolute name of PATH. If given, CWD (current working dir) is used
# instead of the current dir when calculating output. PATH defaults to current
# dir (`.`) if not specified. Always succeed and return zero exit status.
#
# Works by cleaning up all occurances of '..' / '.', multiple (and trailing)
# slashes in PATH. Does not access the file system. Get current dir from the
# $PWD environment variable.
abspath() {
    local REL="${1:-.}" CWD="${2:-$PWD}"
    case "$REL" in
        [!/]*) REL="$CWD/$REL" ;;              # relative = prepend base dir
    esac
    local PART ABS="" IFS="/"
    local -; set -f                            # locally disable globbing
    for PART in $REL; do                       # intentionally unquoted
        case "$PART" in
            .|"") :              ;;            #   do nada
            ..) ABS="${ABS%/*}"  ;;            #   strip last part from result
            *)  ABS="$ABS/$PART" ;;            #   append to result
        esac
    done
    say "${ABS:-/}"
}

# Usage: relpath [PATH [CWD [ABSPATH_CWD]]]
#
# Output relative name of PATH. If given, CWD (current working dir) is used
# instead of the current dir when calculating output. PATH defaults to current
# dir (`.`) if not specified. If PATH is a relative path, then ABSPATH_CWD is
# used as the current working dir when first rewriting it into an absolute
# path. Always succeed and return zero exit status.
#
# Relies on abspath() to clean up path names before processing. Does not access
# the file system.
#
# To change PATH from being relative to dir A into being relative to dir B use
# `relpath PATH B A` (this will expand it relative to A, then rewrite it into
# being relative to B).
relpath() {
    local ABS="${1:-.}" CWD="${2:-.}" ABSCWD="${3:-}"
    setrun ABS abspath "$ABS" "$ABSCWD"; ABS="${ABS%/}/"
    setrun CWD abspath "$CWD";           CWD="${CWD%/}/"
    # For each dir part in CWD, except the leading prefix shared with ABSFILE,
    # add one '..' part to the beginning of the output.
    local REL=""
    while [ "${ABS#"$CWD"}" = "$ABS" ]; do     # while CWD not prefix of ABS
        CWD="${CWD%/*/}/"                      #   remove last part of CWD
        REL="../$REL"                          #   add '..' to output
    done
    REL="${REL:-./}${ABS#"$CWD"}"              # append uniq suffix of ABSFILE
    REL="${REL%/}"                             # strip trailing '/'
    say "${REL#./}"                            # strip leading './'
}

mkpath() {
    local DIR="${1%/*}"                        # strip trailing filename
    [ -d "$DIR" ] || mkdir -p -- "$DIR"
}

# Usage: find_work_tree
#
# Locate work tree root dir. Does a search for a `.fix` dir in the current
# directory, then upwards towards root dir (`/`). If found, return true and
# output name of the dir on standard output, otherwise return false.
find_work_tree() {
    local DIR="$PWD"
    while :; do
        [ -d "$DIR/.fix" ] && break
        [ -z "$DIR"      ] && return 1
        DIR="${DIR%/*}"
    done
    say "${DIR:-/}"
}

# Usage: save_metadata STATEFILE ( TYPE:FILE CHECKSUM )...
#
# Saves build metadata to STATEFILE. The two last arguments may be repeated to
# save multiple lines to STATEFILE.
save_metadata() {
    local STATEFILE="$1" DEPFILE CHECKSUM; shift
    mkpath "$STATEFILE" \
        || die 7 "Cannot create dir for metadata file '%s'" - "$STATEFILE"
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
    if [ -e "$FILE" ]; then
        CHECKSUM="$(sha1sum "$FILE")" || \
            die 31 "file_checksum: Cannot compute SHA1 sum for file '%s'" - \
            "$FILE"
    fi
    echo "${CHECKSUM%% *}"                     # checksum without filename
}

# Return true if this Fix process was invoked from command line, false if it
# was invoked from a buildscript.
is_mother() {
    [ "${FIX_LEVEL:-0}" = "0" ]
}

# Usage: add_fix_to_path DIR
#
# Creates DIR (which must be an absolute path), and puts a hardlink in DIR
# (called `fix`) linking to the currently running executable.
add_fix_to_path() {
    local DIR="$1" LINK="$1/fix" FIX="$(readlink -f "$0")"
    mkpath "$LINK" || die 7 "Cannot create dir for executable '%s'" - "$LINK"
    ln -f "$FIX" "$LINK"
    PATH="$DIR:$PATH"
}

establish_lock() {
    local LOCKFILE="$1" SIG
    mkpath "$LOCKFILE" \
        || die 7 "Cannot create dir for lockfile '%s'" - "$LOCKFILE"
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
    [ -e "$CMD" ] || die 1 "Buildscript '%s' does not exist"            - "$CMD"
    [ -r "$CMD" ] || die 1 "No read permission for buildscript '%s'"    - "$CMD"
    [ -x "$CMD" ] || die 1 "No execute permission for buildscript '%s'" - "$CMD"

    # FIXME: Catch a failure to write to $TMPFILE
    "$CMD" >"$TMPFILE" "$TMPFILE" <&- &        # run buildscript
    wait "$!" || die 1 "Buildscript '%s' returned exit status $?" \
        "Old target unchanged. New, failed target written to '%s'." \
        "$CMD" "$TMPFILE"
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
        die 1 "Old target '%s' modified by user, won't overwrite" \
            "Erase old target before rebuild. New target kept in '%s'." \
            "$FILE" "$TMPFILE"
    fi
    mv -f -- "$TMPFILE" "$FILE"
}

# Usage: strip_path TYPE FILE
#
# Where TYPE is 'SCRIPT', 'SOURCE' or 'TARGET'. Strip $FIX_[TYPE]_DIR off of
# FILE and output the result on standard output.
strip_path() {
    local TYPE="$1" FILE="$2" DIR=""
    case "$TYPE" in
        SCRIPT) DIR="$FIX_SCRIPT_DIR" ;;
        SOURCE) DIR="$FIX_SOURCE_DIR" ;;
        TARGET) DIR="$FIX_TARGET_DIR" ;;
        *) die 30 "strip_path: Unknown type '$TYPE' for file '$FILE'"
            "Type must be 'SCRIPT', 'SOURCE' or 'TARGET'." ;;
    esac
    say "$TYPE:${FILE#$DIR/}"
}

# After build: Overwrite target with tempfile, and store result in metadata.
build_finalize() {
    local DBFILE="$1" TARGET="$2" TARGET_TMP="$3" SCRIPT="$4" PARENT="$5"
    local TMP_CHECKSUM="$(file_checksum "$TARGET_TMP")" FILE=""
    setrun FILE strip_path TARGET "$TARGET"

    # update target
    local OLD_CHECKSUM="$(load_metadata "$DBFILE" "$FILE")"
    finalize_tmpfile "$TARGET_TMP" "$TARGET" \
        "$TMP_CHECKSUM" "$OLD_CHECKSUM"

    # finalize metadata
    if [ "$PARENT" ]; then
        local DBPATH="${DBFILE%/*}"
        local DBFILE2="$DBPATH/$PARENT"
        save_metadata "$DBFILE2--fixing" "$FILE" "$TMP_CHECKSUM"
    fi

    # write to metadata tempfile
    local SCRIPT_CHECKSUM="$(file_checksum "$SCRIPT")"
    save_metadata "$DBFILE--fixing" \
        "SCRIPT:${SCRIPT#$FIX_SCRIPT_DIR/}" "$SCRIPT_CHECKSUM" \
        "$FILE"                             "$TMP_CHECKSUM"
    reverse_file "$DBFILE--fixing" \
        && mv -f -- "$DBFILE--fixing" "$DBFILE" >&2
}

# Usage: build TARGET [PARENT]
#
# Build TARGET (atomically) by executing the corresponding buildscript. If
# TARGET is a dependency of another target PARENT (the name of the dependant
# taget) must also be specified.
#
# TARGET and PARENT are both filenames which should be either absolute paths,
# or written relative to $FIX_TARGET_DIR.
build() {
    local TARGET="$1" PARENT="${2:-}" FILE SCRIPT DBFILE
    setrun TARGET abspath "$TARGET"   "$FIX_TARGET_DIR"
    setrun FILE   relpath "$TARGET"   "$FIX_TARGET_DIR"
    setrun SCRIPT abspath "$FILE.fix" "$FIX_SCRIPT_DIR"
    setrun DBFILE abspath "$FILE"     "$FIX_DIR/state"
    case "$TARGET" in
        "$FIX_TARGET_DIR"/*) : ;;
        *) die 16 "Target '%s' must be inside Fix target dir '%s/'" - \
            "$TARGET" "$FIX_TARGET_DIR" ;;
    esac
    mkpath "$TARGET" || die 6 "Cannot create dir for target '%s'" - "$TARGET"
    build_run "$SCRIPT" "$TARGET" "$TARGET--fixing"
    build_finalize "$DBFILE" "$TARGET" "$TARGET--fixing" "$SCRIPT" "$PARENT"
}

parseopts_case_code() {
    local INNER OUTER
    setrun INNER read_stdin
    setrun OUTER read_stdin <<-"END_CODE"
	case "$ARG" in
	    --) while [ "$COUNT" -gt 0 ]; do   # no options after '--'
	            set -- "$@" "$1"; shift    #   keep remaining args
	            COUNT="$(( COUNT - 1 ))"
	        done; break ;;                 # stop processing options
	    %s
	    -*) die 15 "Unknown option '$ARG'" "$HELP" ;;
	    *)  set -- "$@" "$ARG" ;;          #   put non-option arg back
	esac
	END_CODE
    printf "$OUTER\n" "$INNER"
}

parseopts() {
    local CMD="$1"; shift
    local COUNT="$#" ARG OPTARG OPT_CASE \
        HELP="Try '${0##*/} --help' for more information."
    setrun OPT_CASE parseopts_case_code
    while [ "$COUNT" -gt 0 ]; do
        ARG="$1"; shift
        case "$ARG" in                         # handle '--opt=ARG'
            --[a-z]*=*)                        #   if has '=ARG'
                set -- "${ARG#*=}" "$@"        #     put ARG back into $@
                ARG="${ARG%%=*}"               #     strip off '=ARG' part
                OPTARG=unused ;;
            *)  COUNT="$(( COUNT - 1 ))"
                OPTARG="" ;;
        esac
        eval "$OPT_CASE"
        case "$OPTARG" in
            unused) die 15 "Option '$ARG' doesn't allow an argument" "$HELP" ;;
            used) [ "$COUNT" -eq 0 ] \
                    && die 15 "Option '$ARG' requires an argument" "$HELP"
                COUNT="$(( COUNT - 1 ))"; shift ;;
        esac
    done
    set -- "$CMD" "$@"
    unset ARG CMD COUNT HELP OPTARG OPT_CASE
    "$@"
}

main() {
    [ "$OPT_HELP"    ] && usage
    [ "$OPT_VERSION" ] && version
    [ "$OPT_INIT"    ] && init "$PWD/.fix"

    [ "$#" = 0 ] && die 15 "No target(s) specified"
    if is_mother; then                         # mother process
        export FIX_DEBUG FIX_FORCE FIX_WORK_TREE
        setrun FIX_WORK_TREE find_work_tree \
            || die 14 "Not inside a Fix work tree (Have you run 'fix --init'?)"
        export FIX_PID="$$"
        export FIX_DIR="$FIX_WORK_TREE/.fix"
        export FIX_LOCK="$FIX_DIR/lock.pid"
        export FIX_PWD="$PWD"
        export FIX_SCRIPT_DIR="$FIX_WORK_TREE/fix"
        export FIX_SOURCE_DIR="$FIX_WORK_TREE/src"
        export FIX_TARGET_DIR="$FIX_WORK_TREE/build"
        add_fix_to_path "$(readlink -f "$FIX_DIR")/bin"
        [ -n "$OPT_SOURCE" ] \
            && die 15 "Option '--source' can only be used inside buildscript"
        [ -d "$FIX_SOURCE_DIR" ] \
            || die 10 "Source dir '%s' does not exist" - "$FIX_SOURCE_DIR"
        [ -d "$FIX_SCRIPT_DIR" ] \
            || die 10 "Script dir '%s' does not exist" - "$FIX_SCRIPT_DIR"
        establish_lock "$FIX_LOCK" \
            || die 8 "Cannot create lockfile '%s'" \
            "Is Fix already running? Is the lockfile dir writeable?" "$FIX_LOCK"
    fi

    # Make sure $FIX_SOURCE_DIR is the current dir.
    if [ "$PWD" != "$FIX_SOURCE_DIR" ]; then
        cd "$FIX_SOURCE_DIR" 2>/dev/null \
            || die 10 "Cannot change current dir to '%s'" - "$FIX_SOURCE_DIR"
    fi

    PARENT="${FIX_TARGET:-}"
    if [ "$OPT_SOURCE" ]; then
        for SOURCE; do
            FULL="$FIX_SOURCE_DIR/$SOURCE"
            [ -e "$FULL" ] || die 1 "Source file '%s' does not exist" - "$FULL"
            [ -r "$FULL" ] || die 1 "No read permission for source file '%s'" - \
                "$FULL"
            DBFILE="$FIX_DIR/state/$PARENT"
            CHECKSUM="$(file_checksum "$FULL")"
            save_metadata "$DBFILE--fixing" "SOURCE:$SOURCE" "$CHECKSUM"
        done
    else
        if is_mother; then
            CWD="$FIX_PWD"
        else
            CWD="$FIX_TARGET_DIR"
        fi
        for TARGET; do
            export FIX_TARGET
            setrun FIX_TARGET relpath "$TARGET" "$FIX_TARGET_DIR" "$CWD"
            build "$FIX_TARGET" "$PARENT"
        done
    fi
}

# OPT_* variables are not exported.
# FIX_* variables are exported and inherited by child processes.
export FIX_LEVEL="$(( ${FIX_LEVEL:--1} + 1 ))" # 0 = mother, >0 = child
: ${FIX_DEBUG:=""}                             # --debug  (default off)
: ${FIX_FORCE:=""}                             # --force  (default off)
OPT_HELP=""                                    # --help
OPT_INIT=""                                    # --init
OPT_SOURCE=""                                  # --source
OPT_VERSION=""                                 # --version

parseopts main "$@" <<-"END_CODE"
-D|--debug)   FIX_DEBUG=1   ;;
-f|--force)   FIX_FORCE=1   ;;
-h|--help)    OPT_HELP=1    ;;
--init)       OPT_INIT=1    ;;
--source)     OPT_SOURCE=1  ;;
-V|--version) OPT_VERSION=1 ;;
END_CODE

#[eof]
