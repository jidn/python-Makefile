#!/usr/bin/env sh
. ./helper.sh

function test_run() {
  # $1 Source directory
  make clean-env > log.txt
  # Generate generic RC file
  make env >> log.txt
  $PIP install "$ANALIZE_BIN" >> log.txt
  $ANALIZE --generate-rcfile > pylintrc
  # Now clean up, call check and see if env created properly
  make clean-env

  create_source_file "$1"
  make check > log.txt 2>/dev/null
  grep -qs 'unused-argument' log.txt || err "Didn't find unused-argument"
  pip_reinstall_on_make check

  mkdir $TESTDIR
  create_test_file "$1" "$TESTDIR"
  make docstring  > log.txt 2>/dev/null
  grep -qs D413 log.txt || err "Expecting missing line after 'Returns'"
}

magenta "## Checking static analysic"
start_isolation
ANALIZE=$(makefile_var '^ANALIZE := ')
ANALIZE_BIN=$(basename "$ANALIZE")
PIP=$(makefile_var '^PIP := ')
TESTDIR=$(makefile_var "^TESTDIR = ")
msg "Single source file without src directory"

test_run ''
end_isolation

msg "Source directory"
start_isolation
mkdir "src"
makefile_change_PACKAGE src
test_run "src"
end_isolation


