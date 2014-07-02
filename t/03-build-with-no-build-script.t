#!/usr/bin/env dash
# -*- sh -*-
. "t/test-functions.sh"

cat <<"EOF" | note
Attempt to build target when there is no build script for it.
EOF

CMD="../../fix.sh"
cd ${0%.t}
trap 'rm -fr stdout stderr build' 0
$CMD TARGET >stdout 2>stderr
has_exit_status 1                                       "Exit status"
file_is stderr "ERROR: Build script 'fix/TARGET.fix' does not exist" \
                                                        "Standard error"
file_is stdout ""                                       "Standard output"
# FIXME: Check that tempfile does not exist

done_testing

#[eof]
