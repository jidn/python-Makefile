#!/usr/bin/env sh
. ./helper.sh
ISOLATE=test-env
ENV=travis


magenta "## TRAVIS virtual environment"
rm -rf $ISOLATE
mkdir "$ISOLATE"; pushd "$ISOLATE" > /dev/null
copy_makefile
# Creating environment as if travis-ci.org
make env ENV=$ENV > log.txt

export TRAVIS=1
source ${ENV}/bin/activate
echo "$VIRTUAL_ENV" | grep -q "/travis$" || err "\$VIRTUAL_ENV is $VIRTUAL_ENV"

create_source_file ''
make -n pep257 >> log.txt
grep -q "travis/bin/pydocstyle" log.txt || err "Not using travis virtualenv"
popd >/dev/null
rm -rf $ISOLATE
