#!/usr/bin/env sh
. ./helper.sh
ENV=travis

magenta "## TRAVIS virtual environment"
start_isolation
# Creating environment as if travis-ci.org
make env ENV=$ENV > log.txt
grep -q "$ENV/bin/pip" log.txt || err "Unable to create $ENV virtual environment"
# Activate Travis-CI environment
export TRAVIS=1
. $ENV/bin/activate

# See if Makefile trys to install TEST_RUNNER from virtual environment
make -n test | grep -q "/$ENV/bin/pip" || err "Not using virtual environment"
end_isolation
