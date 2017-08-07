#!/usr/bin/env sh
. ./helper.sh
TESTDIR=test-env

mkdir "$TESTDIR"; pushd "$TESTDIR" > /dev/null
msg "Create environment without requirements.txt"
make clean-env > log.txt
rm -f requirements.txt
make env >> log.txt
[ -d "${ENV}" ] || err "Environment directory should exist."
[ -e ${ENV}/requirements.log ] || err "Requirements log is missing."
[ ! -s ${ENV}/requirements.log ] || err "Requirements log is not empty "

msg "Create environment with requirements.txt"
PKG="obscure"
make clean-env >log.txt
echo "$PKG" >requirements.txt
make env >> log.txt
[ -d "$ENV" ] || err "Environment directory should exist."
[ -e ${ENV}/requirements.log ] || err "Requirements log is missing."
grep -qs "$PKG" ${ENV}/requirements.log || err "'$PKG' missing from log"
${ENV}/bin/python -c "import $PKG" || err "unable to import '$PKG'"

msg "Repeated 'make env' does nothing"
cp -p ${ENV}/requirements.log ${ENV}/bak
make env >> log.txt
[ ${ENV}/requirements.log -nt ${ENV}/bak ] && err "Requirements log shouldn't change"

sleep 2
msg "Changed requirements.txt triggers adds package"
PKG="six"
echo "$PKG" >>requirements.txt
make env >> log.txt
[ ${ENV}/bak -ot ${ENV}/requirements.log ] || err "Requirements log should change"
grep -qs "$PKG" ${ENV}/requirements.log || err "'$PKG' missing from log"
${ENV}/bin/python -c "import $PKG" || err "unable to import '$PKG'"

msg "Create envirnoment with commandline REQUIRE="
PKG="six"
make clean-env >log.txt
echo "$PKG" >my_requirements.txt
make env REQUIRE=my_requirements.txt >> log.txt
[ -d "$ENV" ] || err "Environment directory should exist."
[ -e ${ENV}/requirements.log ] || err "Requirements log is missing."
grep -qs "$PKG" ${ENV}/requirements.log || err "'$PKG' missing from log"
${ENV}/bin/python -c "import $PKG" || err "unable to import '$PKG'"

# Cleanup after tests
popd >/dev/null
rm -rf "$TESTDIR"
