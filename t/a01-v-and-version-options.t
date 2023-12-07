#!/usr/bin/env dash
# -*- sh -*-
# Copyright (C) 2015 zrajm <fix@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "dashtap/dashtap.sh"
title - <<"EOF"
Should return correct version information. (Dirs required for normal build
should not be required, nor created.)
EOF

############################################################################
##                                                                        ##
##  Functions                                                             ##
##                                                                        ##
############################################################################

# Usage: match PATTERN STRING
match() { eval 'case "$2" in ($1) return 0 ;; esac; return 1'; }

# Get latest major & minor version numbers from last version tag in git.
last_git_tag() {
    local PATTERN="$1" LINE TAG="" IFS=""
    git for-each-ref --sort=taggerdate --format '%(tag)' refs/tags | {
        while read -r LINE; do
            TAG="$LINE"
        done
        echo "$TAG"
        [ "$TAG" ] && return 0
        return 1
    }
}

# Count number of commits since last tag.
commits_since_tag() {
    local TAG="$1" FILE="$2" LINE PATCH=0 IFS=""
    git log --follow --oneline "$TAG".. -- "$FILE" | {
        while read -r LINE; do
            PATCH=$(( PATCH + 1 ))
        done
        echo "$PATCH"
    }
}

die() {
    local STATUS="$1" MSG="$2" EXTRA="${3:-}"
    echo "ERROR: $MSG" >&2
    [ "$EXTRA" ] && echo "    ($EXTRA)" >&2
    exit "$STATUS"
}

############################################################################
##                                                                        ##
##  Main                                                                  ##
##                                                                        ##
############################################################################

# Get last Git tag = version number (vX.Y).
TAG="$(last_git_tag 'v*.*')" || die "No git tag found matching 'v*.*'"

# Extract minor + major version number and verify that they're numbers.
VER="${TAG#v}"                                 # strip leading 'v'
MAJOR="${VER%.*}"                              # first number
MINOR="${VER#*.}"                              # last number
match '*[!0-9]*' "$MAJOR" && die "Major version '$MAJOR' is not numeric"
match '*[!0-9]*' "$MINOR" && die "Minor version '$MAJOR' is not numeric"

# Patch number = number of commits of file 'fix' since last version tag.
PATCH="$(commits_since_tag "$TAG" fix.sh)"

if git diff --quiet HEAD "fix.sh"; then
    # 'fix.sh' has NOT been modified since last commit.
    set "$MAJOR.$MINOR.$PATCH"
    WANTED_YEAR=""
else
    # 'fix.sh' has been modified since last commit.
    set -- \
        "$MAJOR.$MINOR.$(( PATCH + 1 ))" \
        "$MAJOR.$(( MINOR + 1 )).0" \
        "$(( MAJOR + 1 )).0.0"
    WANTED_YEAR="2014-$(date +%Y)"
fi

init_test

file_not_exists .fix   "Before build: Metadata dir shouldn't exist"
file_not_exists build  "Before build: Target dir shouldn't exist"
file_not_exists fix    "Before build: Buildscript dir shouldn't exist"
file_not_exists src    "Before build: Metadata dir shouldn't exist"

"$TESTCMD" --version  >stdout 2>stderr; RC="$?"

# Version number into $VER, rest of version message into $GOT.
{
    read -r GOT                                # read 1st line
    VER="${GOT##* }"                           # get last word (version number)
    GOT="${GOT% *}"                            # strip last word
    while read -r LINE; do                     # read remaining lines
        GOT="$GOT$NL$LINE"
    done
    GOT_YEAR="${GOT#*Copyright (C) }"          # extract copyright year
    GOT_YEAR="${GOT_YEAR%% *}"
    WANTED_YEAR="${WANTED_YEAR:-$GOT_YEAR}"    # if Fix hasn't changed
} <stdout

# Version output with version number removed (from end of first line).
OUTPUT="fix.sh (Fix)
Copyright (C) ${WANTED_YEAR:-$GOT_YEAR} zrajm <fix@zrajm.org>
License GPLv2: GNU GPL version 2 <https://gnu.org/licenses/gpl-2.0.txt>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

For the latest version of Fix, see <https://github.com/zrajm/fix.sh>."

is_one_of "$VER" "Version number" -- "$@"
is        "$GOT_YEAR" "$WANTED_YEAR" "Copyright year"

is              "$RC"  0             "Exit status"
file_not_exists .fix   "Metadata dir shouldn't exist"
file_not_exists build  "Target dir shouldn't exist"
file_not_exists fix    "Buildscript dir shouldn't exist"
file_not_exists src    "Metadata dir shouldn't exist"
is              "$GOT" "$OUTPUT"     "Standard output"
file_is         stderr "$NADA"       "Standard error"

# Everything should be the same with '-V' instead of '--version'.
"$TESTCMD" -V  >stdout2 2>stderr2; RC="$?"

is              "$RC"  0             "Exit status with -V"
setread STDOUT <stdout
file_is         stdout2 "$STDOUT"    "Standard output with -V"
file_is         stderr "$NADA"       "Standard error with -V"

file_not_exists .fix   "After build: Metadata dir shouldn't exist"
file_not_exists build  "After build: Target dir shouldn't exist"
file_not_exists fix    "After build: Buildscript dir shouldn't exist"
file_not_exists src    "After build: Metadata dir shouldn't exist"

done_testing

#[eof]
