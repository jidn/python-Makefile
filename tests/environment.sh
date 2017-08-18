#!/usr/bin/env sh
. ./helper.sh
ISOLATE=test-env
PIP_LOG=.requirements.log

magenta "## Environment"
rm -rf $ISOLATE
mkdir "$ISOLATE"; pushd "$ISOLATE" > /dev/null
copy_makefile
msg "Create environment without requirements.txt"
rm -f requirements.txt
make_env_and_test log.txt
[ ! -s $PIP_LOG ] || err "Requirements log is not empty "

msg "Create environment with requirements.txt"
PKG="obscure"
make clean-env >log.txt
echo "$PKG" >requirements.txt
make_env_and_test log.txt
grep -qs "^Successfully installed $PKG" PIP_LOG && err "'$PKG' missing from log"
${ENV}/bin/python -c "import $PKG" || err "unable to import '$PKG'"

msg "Repeated 'make env' does nothing"
cp -p $PIP_LOG bak
make env >> log.txt
[ $PIP_LOG -nt bak ] && err "Requirements log shouldn't change"

sleep 2
msg "Changed requirements.txt triggers adds package"
PKG="six"
echo "$PKG" >>requirements.txt
make env >> log.txt
[ bak -ot $PIP_LOG ] || err "Requirements log should change"
grep -qs "$PKG" $PIP_LOG || err "'$PKG' missing from log"
${ENV}/bin/python -c "import $PKG" || err "unable to import '$PKG'"

msg "Create environment with commandline REQUIRE="
PKG="six"
make clean-env >log.txt
[ -f .*.log ] && err "Requirements install log not cleaned"
echo "$PKG" >my_requirements.txt
make env REQUIRE=my_requirements.txt >> log.txt
[ -d "$ENV" ] || err "Environment directory should exist."
[ -e $PIP_LOG ] || err "Requirements log is missing."
grep -qs "$PKG" $PIP_LOG || err "'$PKG' missing from log"
${ENV}/bin/python -c "import $PKG" || err "unable to import '$PKG'"

# Cleanup after tests
popd >/dev/null
rm -rf "$ISOLATE"
