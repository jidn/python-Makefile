#!/usr/bin/env sh
. ./helper.sh
TESTDIR=test-env
SRC=src

mkdir "$TESTDIR"; pushd "$TESTDIR" > /dev/null
msg "Check testing and coverage"
make clean-env > log.txt
mkdir "$SRC"
mkdir tests
echo pytest-cov > tests/requirements.txt
make env >> log.txt
[ -d "$ENV" ] || err "Environment directory should exist."
[ -e ${ENV}/requirements.log ] || err "Requirements log is missing."
[ -s ${ENV}/requirements.log ] || err "Requirements log is empty "

### Create a source file
( cat <<'EOF'
def func():
  print("Hello world")
EOF
) > ${SRC}/foo.py

### Create a test file
( cat <<EOF
import os.path as os
import sys
sys.path.insert(0, os.abspath(os.join(os.dirname(__file__), '..')))
from ${SRC}.foo import func

def test_simple():
    func()

def test_failure():
    assert False
EOF
) > tests/simple_test.py

### coveragerc file
COV_RC=tests/.coveragerc
( cat <<EOF
[run]
omit = ${ENV}/
EOF
) > "$COV_RC"

### Run test and coverage
make test args="-v" PACKAGE="${SRC}" >> log.txt 2>/dev/null
grep -q "simple PASSED" log.txt || err "Unable to pass test"
grep -q "failure FAILED" log.txt || err "Expected failure missing"

make coverage args="--cov-config ${COV_RC}" PACKAGE="${SRC}" >> log.txt 2>/dev/null
grep "foo.py" log.txt | grep -q "100%" || error "Expected 100% coverage"
popd >/dev/null
rm -rf "$TESTDIR"
