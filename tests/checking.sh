#!/usr/bin/env sh
. ./helper.sh
ISOLATION=test-env
TESTDIR=tests

function test_run() {
  # $1 Source directory
  # $2 Test directory
  msg "Check flake8 for syntax and style"
  make clean-env > log.txt
  make_env_and_test log.txt

  create_source_file "$1"
  make check >> log.txt 2>/dev/null
  grep -qs E111 log.txt || err "Indentation not multiple of 4"

  msg "Check pep257 Docstring"
  mkdir ${2}
  create_test_file "$1" "$2"
  make pep257  > log.txt 2>/dev/null
  grep -qs foo  log.txt || err "Missing foo.py in top directory"
  grep -qs D100 log.txt || err "Expecting Missing module docstring error"
  grep -qs D103 log.txt || err "Expecting Missing function docstring error"
}

magenta "## Checking static analysic"
rm -rf "$ISOLATION"
msg "Single source file without src directory"
mkdir "$ISOLATION"; pushd "$ISOLATION" >/dev/null
copy_makefile
test_run '' "${TESTDIR}"
popd >/dev/null
rm -rf "$ISOLATION"

msg "Source directory"
mkdir "$ISOLATION"; pushd "$ISOLATION" >/dev/null
copy_makefile
mkdir "src"
makefile_change_PACKAGE src
test_run "src" "${TESTDIR}"
popd >/dev/null
rm -rf "$ISOLATION"


