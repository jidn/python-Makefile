# For source directory should be '' if in project root

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

function copy_makefile() {
  cp ../../Makefile .
  ENV=`make -np -f Makefile | sed '/^ENV = */!d; s///;q'`
}

function make_env_and_test() {
  make clean-env
  make env >> $1
  [ -d "$ENV" ] || err "Environment directory should exist."
  [ -e .requirements.log ] || err "Requirements log is missing."
}

function create_source_file() {
  # $1 source directory 
  local src_dir=$1
  [ -z "$src_dir" ] && src_dir='.'
( cat <<'EOF'
def func():
  pass
EOF
) > ${src_dir}/foo.py
}

function create_test_file() {
# $1 is source directory
# $2 is test directory
### Create a test file
( cat <<EOF
import os.path as os
import sys
sys.path.insert(0, os.abspath(os.join(os.dirname(__file__), '../${1}')))
from foo import func
def test_success():
    func()

def test_failure():
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
