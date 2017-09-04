#!/usr/bin/env sh
. ./helper.sh
ISOLATION=test-env
TESTDIR=tests
SRC=src

magenta "## Testing and coverage"
rm -rf "$ISOLATION"
function setup() {
  # $1 Source directory
  # $2 Test directory
  make clean-env > log.txt

  echo "six" > requirements.txt
  create_source_file "$1"
  mkdir "$2"
  create_test_file "$1" "$2"
}

function test_run() {
  # $1 Source directory
  # $2 Test directory

  msg "Run tests"
  make test args="-v" >> log.txt 2>>err.txt
  grep -q "success PASSED" log.txt || err "Unable to pass test_success"
  grep -q "failure FAILED" log.txt || err "Expected failure missing"
  grep -q "six" log.txt || err "make test should install requirements"

  msg "Run coverage"
  make clean-env > log.txt
  make coverage >> log.txt 2>>err.txt
  grep "foo.py" log.txt | grep -q "100%" || err "Expected 100% coverage"
  grep -q "six" log.txt || err "make coverage should install requirements"
  grep -q "site-package" .coverage && err "coverage found site-packages"
}

msg "Single source file without src directory"
mkdir "$ISOLATION"; pushd "$ISOLATION" > /dev/null
copy_makefile

setup '' "$TESTDIR"
msg "Check for auto .coveragerc creation"
[ -f .coveragerc ] && err "No .coveragerc file should exist now."
make coverage >> log.txt 2>err.txt && err "make $? must stop after creating .coveragerc"
[ ! -f .coveragerc ] && err "Auto generation of .coveragerc failed."
test_run '' "$TESTDIR"
popd >/dev/null
rm -rf "$ISOLATION"

msg "Use a source directory"
mkdir "$ISOLATION"; pushd "$ISOLATION" > /dev/null
copy_makefile
mkdir "src"
makefile_change_PACKAGE src
setup 'src' "$TESTDIR"
test_run 'src' "$TESTDIR"
popd >/dev/null
rm -rf "$ISOLATION"

