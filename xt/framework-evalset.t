#!/usr/bin/env dash
# -*- sh -*-
. "t/dashtap.sh"

##############################################################################

seteval GOT    "printf \"start\\\"'end\""
WANTED="start\"'end\No newline at end"
is "$GOT" "$WANTED" "Strip newline - String with quotes in"

seteval GOT    'printf "AA BB"'
WANTED="AA BB\No newline at end"
is "$GOT" "$WANTED" "Strip newline - String with space inside"

seteval GOT    'printf " AA "'
WANTED=" AA \No newline at end"
is "$GOT" "$WANTED" "Strip newline - String with space at start and end"

seteval GOT    'printf "\nAA\n"'
WANTED="
AA"
is "$GOT" "$WANTED" "Strip newline - String with newline at start and end"

##############################################################################

seteval GOT + "printf \"start\\\"'end\""
WANTED="start\"'end"
is "$GOT" "$WANTED" "Preserve newline - String with quotes in"

seteval GOT + 'printf "AA BB"'
WANTED="AA BB"
is "$GOT" "$WANTED" "Preserve newline - String with space inside"

seteval GOT + 'printf " AA "'
WANTED=" AA "
is "$GOT" "$WANTED" "Preserve newline - String with space at start and end"

seteval GOT + 'printf "\nAA\n"'
WANTED="
AA
"
is "$GOT" "$WANTED" "Preserve newline - String with newline at start and end"

##############################################################################

done_testing

#[eof]
