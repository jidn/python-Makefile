#!/usr/bin/env sh
. ./helper.sh
ISOLATION=test-env
TESTDIR=tests
SRC=src
COVRC=coveragerc

magenta "## Testing and coverage"
rm -rf "$ISOLATION"

function test_run() {
  # $1 Source directory
  # $2 Test directory
  msg "Check testing and coverage"
  make clean-env > log.txt
  make_env_and_test log.txt

  create_source_file "$1"
  mkdir "$2"
  create_test_file "$1" "$2"
  create_coveragerc "$COVRC"

  msg "Run tests"
  make test args="-v" >> log.txt 2>/dev/null
  grep -q "success PASSED" log.txt || err "Unable to pass test_success"
  grep -q "failure FAILED" log.txt || err "Expected failure missing"

  msg "Run coverage"
  make coverage args="--cov-config ${COVRC}" >> log.txt 2>/dev/null
  grep "foo.py" log.txt | grep -q "100%" || err "Expected 100% coverage"
}

msg "Single source file without src directory"
mkdir "$ISOLATION"; pushd "$ISOLATION" > /dev/null
copy_makefile
test_run '' "$TESTDIR"
popd >/dev/null
rm -rf "$ISOLATION"

msg "Use a source directory"
mkdir "$ISOLATION"; pushd "$ISOLATION" > /dev/null
copy_makefile
mkdir "src"
makefile_change_PACKAGE src
test_run 'src' "$TESTDIR"
popd >/dev/null
rm -rf "$ISOLATION"

