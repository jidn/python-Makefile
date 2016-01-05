# PYTHON PROJECT MAKEFILE
# This helps with creating local virtual environments, requirements,
# syntax checking, running tests, coverage and uploading packages to PyPI.
# 
# This also works with Travis CI
# For more information on creating packages for PyPI see the writeup at
# http://peterdowns.com/posts/first-time-with-pypi.html
#
.PHONY help
help:
	@echo "env  Create virtual environment and install requirements"
	@echo "test  Run tests"
	@echo "pdb   Run tests, but stop at the first unhandled exception."
	@echo "check  Run style checks"
	@echo "upload  Upload package to PyPI"
##############################################################################
PROJECT := Flask-RESTeasy
PACKAGE := flask_resteasy.py
REQUIREMENTS := requirements.txt
# Directory with all the tests
TESTDIR := tests
TESTREQUIREMENTS := $(TESTDIR)/$(REQUIREMENTS)
##############################################################################
# Python settings
ifdef TRAVIS
	ENV = $(VIRTUAL_ENV)
else
	# The python version settings to use.  Minor is optional.
	PYTHON_MAJOR := 3
	PYTHON_MINOR := 5
	ENV := env
endif

# System paths
# I haven't developed for windows for a long time, mileage may vary.
PLATFORM := $(shell python -c 'import sys; print(sys.platform)')
ifneq ($(findstring win32, $(PLATFORM)), )
	SYS_PYTHON_DIR := C:\\Python$(PYTHON_MAJOR)$(PYTHON_MINOR)
	SYS_PYTHON := $(SYS_PYTHON_DIR)\\python.exe
	SYS_VIRTUALENV := $(SYS_PYTHON_DIR)\\Scripts\\virtualenv.exe
	# https://bugs.launchpad.net/virtualenv/+bug/449537
	export TCL_LIBRARY=$(SYS_PYTHON_DIR)\\tcl\\tcl8.5
else
	SYS_PYTHON := python$(PYTHON_MAJOR)
	ifdef PYTHON_MINOR
		SYS_PYTHON := $(SYS_PYTHON).$(PYTHON_MINOR)
	endif
	SYS_VIRTUALENV := virtualenv
endif

# virtualenv paths
ifneq ($(findstring win32, $(PLATFORM)), )
	BIN := $(ENV)/Scripts
	OPEN := cmd /c start
else
	BIN := $(ENV)/bin
	ifneq ($(findstring cygwin, $(PLATFORM)), )
		OPEN := cygstart
	else
		OPEN := xdg-open
	endif
endif

# virtualenv executables
PIP := $(BIN)/pip
PYTHON := $(BIN)/python
FLAKE8 := $(BIN)/flake8
PEP257 := $(BIN)/pep257
COVERAGE := $(BIN)/coverage
TESTRUN := $(BIN)/py.test

# Project settings
SOURCES := Makefile setup.py \
	       $(shell find $(PACKAGE) -name '*.py')
TESTS :=   $(shell find $(TESTDIR) -name '*.py')
EGG_INFO := $(subst -,_,$(PROJECT)).egg-info

# Flags for environment/tools
ALL := $(ENV)/.all
DEPENDS_CI := $(ENV)/.depends-ci
DEPENDS_DEV := $(ENV)/.depends-dev
DEPENDS_TEST := $(ENV)/.depends-test
# Main Targets ###############################################################
.PHONY: all env
all: env $(ALL)
$(ALL): $(SOURCES)
	$(MAKE) check
	@touch $(ALL)  # flag to indicate all setup steps were successful

# Targets to run on Travis
.PHONY: ci
ci: test

# Environment Installation ###################################################
env: $(PIP) requirements.txt $(EGG_INFO)
$(PIP):
	$(SYS_VIRTUALENV) --python $(SYS_PYTHON) $(ENV)

requirements.txt:
	$(PIP) install --upgrade -r requirements.txt
	@echo "Upgrade or install requirements.txt complete."

$(EGG_INFO): setup.py
	$(PIP) install -e .
	@touch $(EGG_INFO)  # flag to indicate package is installed

### Static Analysis & Travis CI ##############################################
.PHONY: check flake8 pep257

PEP8_IGNORED := E501,E123,D104,D203
check: flake8 pep257

$(DEPENDS_CI): env $(TESTREQUIREMENTS)
	$(PIP) install --upgrade flake8 pep257
	@touch $(DEPENDS_CI)  # flag to indicate dependencies are installed

$(DEPENDS_DEV): env
	$(PIP) install --upgrade wheel  # pygments wheel
	@touch $(DEPENDS_DEV)  # flag to indicate dependencies are installed

flake8: $(DEPENDS_CI)
	$(FLAKE8) $(PACKAGE) $(TESTDIR) --ignore=$(PEP8_IGNORED)

pep257: $(DEPENDS_CI)
	$(PEP257) $(PACKAGE) $(TESTDIR) --ignore=$(PEP8_IGNORED)

### Testing ##################################################################
.PHONY: test pdb coverage

TESTRUN_OPTS := --cov $(PACKAGE) \
			   --cov-report term-missing \
			   --cov-report html 

test: env $(DEPENDS_CI) $(TESTS) $(DEPENDS_TEST)
	$(TESTRUN) $(TESTDIR)/*.py $(TESTRUN_OPTS)

pdb: env $(DEPENDS_CI) $(TEST) $(DEPENDS_TEST)
	$(TESTRUN) $(TESTDIR)/*.py $(TESTRUN_OPTS) -x --pdb

$(DEPENDS_TEST): $(TESTREQUIREMENTS)
	$(PIP) install --upgrade -r $(TESTREQUIREMENTS)
	@touch $(DEPENDS_TEST)
	@echo "Testing requirements installed."

coverage: test
	$(COVERAGE) html
	$(OPEN) htmlcov/index.html

# Cleanup ####################################################################
.PHONY: clean clean-env clean-all .clean-build .clean-test .clean-dist

clean: .clean-dist .clean-test .clean-build
	rm -rf $(ALL)

clean-env: clean
	rm -rf $(ENV)

clean-all: clean clean-env

.clean-build:
	find tests -name '*.pyc' -delete
	find -name $(PACKAGE).c -delete
	find tests -name '__pycache__' -delete
	rm -rf $(EGG_INFO)

.clean-test:
	rm -rf .coverage
#	rm -f *.log

.clean-dist:
	rm -rf dist build

# Release ####################################################################
.PHONY: authors register dist upload .git-no-changes

authors:
	echo "Authors\n=======\n\nA huge thanks to all of our contributors:\n\n" > AUTHORS.md
	git log --raw | grep "^Author: " | cut -d ' ' -f2- | cut -d '<' -f1 | sed 's/^/- /' | sort | uniq >> AUTHORS.md

register: 
	$(PYTHON) setup.py register -r pypi

dist: test
	$(PYTHON) setup.py sdist
	$(PYTHON) setup.py bdist_wheel

upload: .git-no-changes register
	$(PYTHON) setup.py sdist upload -r pypi
	$(PYTHON) setup.py bdist_wheel upload -r pypi

.git-no-changes:
	@if git diff --name-only --exit-code;         \
	then                                          \
		echo Git working copy is clean...;        \
	else                                          \
		echo ERROR: Git working copy is dirty!;   \
		echo Commit your changes and try again.;  \
		exit -1;                                  \
	fi;

# System Installation ########################################################
.PHONY: develop install download
# Is this section really needed?

develop:
	$(SYS_PYTHON) setup.py develop

install:
	$(SYS_PYTHON) setup.py install

download:
	$(PIP) install $(PROJECT)
