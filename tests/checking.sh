#!/usr/bin/env sh
. ./helper.sh
TESTDIR=test-env

mkdir "$TESTDIR"; pushd "$TESTDIR" >/dev/null
msg "Check flake8 for syntax and style"
make clean-env > log.txt
make env >> log.txt
[ -d "$ENV" ] || err "Environment directory should exist."
[ -e ${ENV}/requirements.log ] || err "Requirements log is missing."
[ ! -s ${ENV}/requirements.log ] || err "Requirements log is not empty "

### Create a source file
( cat <<'EOF'
def func():
  print("Hello world", file=sys.null)
EOF
) > foo.py

make check >> log.txt 2>/dev/null
grep -qs E111 log.txt || err "Indentation not multiple of 4"
grep -qs F821 log.txt || err "Undefined module sys"

msg "Check pep257 Docstring"
mkdir tests
( cat <<'EOF'
def test_bar():
    print("I am bar.")
EOF
) > tests/bar.py

make pep257  2> log.txt
grep -qs foo log.txt || err "Missing foo.py in top directory"
grep -qs bar log.txt || err "Missing bar.py in test directory"

popd >/dev/null
rm -rf "$TESTDIR"
