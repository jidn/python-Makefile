#!/usr/bin/env sh
. ./helper.sh

magenta "## Environment"
start_isolation
REQUIREMENTS=$(makefile_var "^REQUIRE = ")
#"Create environment without $REQUIREMENTS"
rm -f $REQUIREMENTS
make_env_and_verify log.txt
[ ! -s $REQUIREMENTS_LOG ] || err "Requirements log is not empty "

msg "Create environment with $REQUIREMENTS"
PKG="obscure"
make clean-env >log.txt
echo "$PKG" >$REQUIREMENTS
make_env_and_verify log.txt
grep -qs "^Successfully installed $PKG" REQUIREMENTS_LOG && err "'$PKG' not installed"
${ENV}/bin/python -c "import $PKG" || err "unable to import '$PKG'"
pip_reinstall_on_make env

sleep 1
msg "Changed $REQUIREMENTS triggers adds package"
PKG="six"
echo "$PKG" >>$REQUIREMENTS
cp -p $REQUIREMENTS_LOG bak
make env >> log.txt
[ bak -ot $REQUIREMENTS_LOG ] || err "Requirements log should change"
grep -qs "$PKG" $REQUIREMENTS_LOG || err "'$PKG' missing from log"
${ENV}/bin/python -c "import $PKG" || err "unable to import '$PKG'"

msg "Create environment with commandline REQUIRE= for alternate requirements"
make clean-env >log.txt
PKG="six"
[ -f .*.log ] && err "Requirements install log not cleaned"
echo "$PKG" >my_requirements.txt
make env REQUIRE=my_requirements.txt >> log.txt
[ -d "$ENV" ] || err "Environment directory should exist."
[ -e $REQUIREMENTS_LOG ] || err "Requirements log is missing."
grep -qs "$PKG" $REQUIREMENTS_LOG || err "'$PKG' missing from log"
${ENV}/bin/python -c "import $PKG" || err "unable to import '$PKG'"

end_isolation
