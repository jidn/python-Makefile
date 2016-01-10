#!/usr/bin/env sh
# Ensure we get the python version to use.
if [[ "$#" -ne 1 ]]; then 
  echo "Give the python version.  This is appended to the word python."
  echo "   Example"
  echo "     '' for python"
  echo "     3 for python3"
  echo "     2.7 for python2.7"
  exit 1
  fi

PYTHON=$1
TAB="\t"

echo "Downloading generic Makefile for python${PYTHON} projects."
curl https://raw.githubusercontent.com/jidn/python-Makefile/master/Makefile > Makefile
#cp ../python-Makefile/Makefile .

# Set the python interpreter to the one specified on command-line
CMD="/PYTHON_VERSION :=/ s/\$/${PYTHON}/"
#echo "COMMAND $CMD"
sed -i -e "$CMD" Makefile

# No TESTDIR
sed -i '/TESTDIR :=/c\TESTDIR := ' Makefile

# SOURCES to be ./*.py
# All the python files are in this one directory.  Change the 
# the SOURCES to have only look at this directory.
sed -i 's/find \$(PACKAGE)/& -maxdepth 1/' Makefile

# New default target
# Instead of target 'all' 
sed -i '/MAKE) check/c\\${TAB}sh foo.sh' Makefile

# hook for building additional requirements
sed -i "/requirements hook/c\\${TAB}sh extra_install.sh" Makefile

#diff Makefile ~/project/python-Makefile/Makefile

