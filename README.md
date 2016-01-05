Standard Makefile for many of my python projects.  It includes support for virtual environments, requirements, syntax checking, running tests, coverage and uploading packages to PyPI.

Travis CI is also supported, see the  `travis.yml`, but remember to change the name of the file as required to `.travis.yml` (adding a leading dot) for proper Travis CI working.

Copy this file and make the following changes:

 * PROJECT := MyProject
 * PACKAGE := myproject/  or myproject.py
 * REQUIREMENTS := The file with required packages. Defaults to requirements.txt
 * TESTDIR := Default is current directory 'tests'
 * TESTREQUIREMENTS := Required packages needed to run tests. Defaults to TESTDIR/REQUIREMENTS.  If you use a path in REQUIREMENTS, the you should remove the REQUIREMENTS as part of this definition and just enter the file name.
 * PYTHON_MAJOR := The version of python interpreter to use.
 * PYTHON_MINOR := The minor version of python interpreter to use.

## Targets

### env
Create the virtual environment in `env` directory within the current directory.  No stomping on other virtual environments in some global directory.  Lets keep everything local to make environment debugging easier.  This is also were all the requirements are installed.

### test
Run all the tests in TESTDIR.  By default, I am using pytest, but you can fix this by changing TESTRUN and TESTRUN_OPTS.

There is also a `pdb` target to run tests and break at an unhandled exception.

### coverage
Check the coverage and show the text output.  It also creates the HTML output.

### check
Check for code and tests for using flake8 and for proper docstring

### upload
Package the module and upload it PyPI.

## Other files

### travis.yml
A simple `.travis.yml` for python versions 2.7, 3.2, 3.3, and 3.4 in continuous integration testing.  I am not using 3.5 as wheel is giving me some problems when compiling dependencies.

### gitignore
Here is the `.gitignore` file I use.  I am not sure about the source of inspiration, but I have been using this for quite awhile.
