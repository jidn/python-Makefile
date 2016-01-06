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
echo "Downloading generic Makefile for python${PYTHON} projects."
curl https://raw.githubusercontent.com/jidn/python-Makefile/master/Makefile > Makefile

# Set the python interpreter to the one specified on command-line
sed -i "s/PYTHON_VERSION \*:.*\\\$/PYTHON_VERSION := ${PYTHON}/" Makefile
