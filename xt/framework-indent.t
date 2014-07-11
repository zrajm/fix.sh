#!/usr/bin/env dash
# -*- sh -*-
. "t/test-functions.sh"

##############################################################################

seteval GOT    'indent ""'
seteval WANTED 'printf ""'
is "$GOT" "$WANTED" "No prefix + no input"

seteval GOT    'indent "" ""'
seteval WANTED 'printf ""'
is "$GOT" "$WANTED" "No prefix + empty arg"

seteval GOT    'indent "" "1"'
seteval WANTED 'printf " 1\n"'
is "$GOT" "$WANTED" "No prefix + simple arg"

seteval ARG    'printf "1\n2\n"'
seteval GOT    'indent "" "$ARG"'
seteval WANTED 'printf " 1\n 2\n"'
is "$GOT" "$WANTED" "No prefix + two-line arg"

seteval GOT    'printf "" | indent ""'
seteval WANTED 'printf ""'
is "$GOT" "$WANTED" "No prefix + empty stdin"

seteval GOT    'printf "1\n" | indent ""'
seteval WANTED 'printf " 1\n"'
is "$GOT" "$WANTED" "No prefix + one line on stdin"

seteval GOT    'printf "1\n2\n" | indent ""'
seteval WANTED 'printf " 1\n 2\n"'
is "$GOT" "$WANTED" "No prefix + two lines on stdin"

seteval GOT    'printf "2\n" | indent "" "1"'
seteval WANTED 'printf " 1\n 2\n"'
is "$GOT" "$WANTED" "No prefix + one line on stdin + arg"

##############################################################################

seteval GOT    'indent " "'
seteval WANTED 'printf ""'
is "$GOT" "$WANTED" "Space as prefix + no input"

seteval GOT    'indent " " ""'
seteval WANTED 'printf ""'
is "$GOT" "$WANTED" "Space as prefix + empty arg"

seteval GOT    'indent " " "1"'
seteval WANTED 'printf "  1\n"'
is "$GOT" "$WANTED" "Space as prefix + simple arg"

seteval ARG    'printf "1\n2\n"'
seteval GOT    'indent " " "$ARG"'
seteval WANTED 'printf "  1\n  2\n"'
is "$GOT" "$WANTED" "Space as prefix + two-line arg"

seteval GOT    'printf "" | indent " "'
seteval WANTED 'printf ""'
is "$GOT" "$WANTED" "Space as prefix + empty stdin"

seteval GOT    'printf "2\n" | indent " " "1"'
seteval WANTED 'printf "  1\n  2\n"'
is "$GOT" "$WANTED" "Space as prefix + one line on stdin + one arg"

seteval GOT    'printf "1\n2\n" | indent " "'
seteval WANTED 'printf "  1\n  2\n"'
is "$GOT" "$WANTED" "Space as prefix + two lines on stdin"

seteval GOT    'printf "1\n" | indent " "'
seteval WANTED 'printf "  1\n"'
is "$GOT" "$WANTED" "Space as prefix + one line on stdin"

##############################################################################

seteval GOT    'indent ">"'
seteval WANTED 'printf ">\n"'
is "$GOT" "$WANTED" "String prefix + no input"

seteval GOT    'indent ">" ""'
seteval WANTED 'printf ">\n"'
is "$GOT" "$WANTED" "String prefix + empty arg"

seteval GOT    'indent ">" "1"'
seteval WANTED 'printf "> 1\n"'
is "$GOT" "$WANTED" "String prefix + simple arg"

seteval ARG    'printf "1\n2\n"'
seteval GOT    'indent ">" "$ARG"'
seteval WANTED 'printf "> 1\n  2\n"'
is "$GOT" "$WANTED" "String prefix + two-line arg"

seteval GOT    'printf "" | indent ">"'
seteval WANTED 'printf ">\n"'
is "$GOT" "$WANTED" "String prefix + empty stdin"

seteval GOT    'printf "1\n" | indent ">"'
seteval WANTED 'printf "> 1\n"'
is "$GOT" "$WANTED" "String prefix + one line on stdin"

seteval GOT    'printf "1\n2\n" | indent ">"'
seteval WANTED 'printf "> 1\n  2\n"'
is "$GOT" "$WANTED" "String prefix + two lines on stdin"

seteval GOT    'printf "2\n" | indent ">" "1"'
seteval WANTED 'printf "> 1\n  2\n"'
is "$GOT" "$WANTED" "String prefix + one line on stdin + arg"

##############################################################################

done_testing

#[eof]
