#!/usr/bin/env dash
# -*- sh -*-
. "t/test-functions.sh"

cat <<"EOF" | note
Attempt to build target when there is no script dir.
EOF

CMD="../../fix.sh"
cd ${0%.t}
trap 'rm -f stdout stderr' 0
$CMD TARGET >stdout 2>stderr
has_exit_status 10                                      "Exit status"
file_is stderr "ERROR: Script dir 'fix' does not exist" "Standard error"
file_is stdout ""                                       "Standard output"

done_testing

#[eof]
