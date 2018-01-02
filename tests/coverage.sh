#!/usr/bin/env sh
. ./helper.sh
PKG=obscure

function setup() {
  # $1 Source directory
  make clean-env > log.txt

  echo "$PKG" > $REQUIREMENTS
  create_source_file "$1"
  mkdir "$TESTDIR"
  create_test_file "$1" "$TESTDIR"
}

function test_run() {
  # $1 Source directory

  msg "Run tests"
  make test args="-v" >> log.txt 2>>err.txt
  grep -q "success PASSED" log.txt || err "Unable to pass test_success"
  grep -q "failure FAILED" log.txt || err "Expected failure missing"
  grep -q "$PKG" log.txt || err "make test should install requirements"
  pip_reinstall_on_make "test"

  msg "Run coverage"
  make clean-env > log.txt
  make coverage >> log.txt 2>>err.txt
  grep "example.py" log.txt | grep -q "100%" || err "Expected 100% coverage"
  grep -q "$PKG" log.txt || err "make coverage should install requirements"
  grep -q "site-package" .coverage && err "coverage found site-packages"
  pip_reinstall_on_make coverage
}

magenta "## Testing and coverage"
msg "Single source file without src directory"
start_isolation
SRC=''
TESTDIR=$(makefile_var '^TESTDIR = ')
LOG_REQUIRE=$(makefile_var '^LOG_REQUIRE := ')
REQUIREMENTS=$(makefile_var '^REQUIRE = ')
COVERAGERC=$(makefile_var '^COVERAGE_FILE = ')
setup "$SRC"
msg "Check for auto $COVERAGERC creation"
[ -f "$COVERAGERC" ] && err "No $COVERAGERC file should exist now."
make coverage >> log.txt 2>err.txt && err "make $? must stop after creating $COVERAGERC"
[ ! -f "$COVERAGERC" ] && err "Auto generation of $COVERAGERC failed."
test_run "$SRC"
end_isolation

msg "Use a source directory"
start_isolation
SRC=src
makefile_change_PACKAGE $SRC
mkdir "$SRC"
setup "$SRC"
test_run "$SRC"
end_isolation
