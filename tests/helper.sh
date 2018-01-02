# For source directory should be '' if in project root

# Directory to encapsulate testing of a Makefile environment
ISOLATION=venv-for-test
function start_isolation(){
  rm -rf "$ISOLATION"
  mkdir "$ISOLATION"; pushd "$ISOLATION" >/dev/null
  copy_makefile
}
function end_isolation(){
  popd >/dev/null
  rm -rf "$ISOLATION"
}

# Dummy package for requirements file
PKG='obscure'

function err() {
  tput setaf 1
  echo -n "[$?] "
  echo $1
  tput sgr0
  exit 1
}
function msg() {
  tput setaf 3
  echo $1
  tput sgr0;
}
function magenta() {
  tput setaf 5
  echo $1
  tput sgr0;
}
function green() {
  tput setaf 2
  echo $1
  tput sgr0;
}

function makefile_var() {
  # Get a variable from the Makefile
  local V=`make -np -f Makefile | sed "/$1*/!d; s///;q"`
  [ -z "$V" ] && err "Unable to find $1 in Makefile"
  echo "$V"
}

function copy_makefile() {
  cp ../../Makefile .
}

function make_env_and_verify() {
  make clean-env
  ENV=$(makefile_var '^ENV = ')
  REQUIRE=$(makefile_var '^REQUIRE = ')
  REQUIREMENTS_LOG=$(makefile_var '^REQUIREMENTS_LOG := ')
  make env >> $1
  [ -d "$ENV" ] || err "Virtual environment [ $ENV ] should exist."
  if [ -f "$REQUIRE" ]; then
    [ -e "$REQUIREMENTS_LOG" ] || err "$REQUIREMENTS_LOG is missing."
    pip_reinstall_on_make env
  fi
}

function pip_reinstall_on_make () {
  make "$1" -n | grep -q 'pip install' && err "Pip attempts to reinstall"
}

function create_source_file() {
  # $1 source directory 
  local src_dir=$1
  [ -z "$src_dir" ] && src_dir='.'
( cat <<'EOF'
"""Dummy docstring."""
def func(src=None):
    """Signal True.

    Args:
      in: No argument needed
  
    Returns:
      boolean: True
    """
    return True
EOF
) > ${src_dir}/example.py
}

function create_test_file() {
# $1 is source directory
# $2 is test directory
  mkdir $2 2>/dev/null
### Create a test file
( cat <<EOF
"""Even test files should have documentation."""
import os.path as os
import sys
sys.path.insert(0, os.abspath(os.join(os.dirname(__file__), '../${1}')))
from example import func
def test_success():
    """Verify truth."""
    func()

def test_failure():
    """Show failure."""
    assert False
EOF
) > $2/test_1.py
}

function makefile_change_PACKAGE() {
  # $1 source directory
  [ -z "$1" ] && 1='.'
  sed -i'' "/^PACKAGE/s/.*/PACKAGE := ${1}/" Makefile
}

function single_file_package() {
  # $1 test directory
  msg "Single source file without source directory"
  create_source_file ''
  mkdir $1
  create_test_file '' $1
  create_coverage
}

function source_directory_package() {
  # $1 source directory
  # $2 test directory
  makefile_change_PACKAGE ${1}
  mkdir ${1}
  create_source_file ${1}
  mkdir tests
  create_test_file "${1}" "${2}"
}
