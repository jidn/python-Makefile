# PYTHON PROJECT MAKEFILE
# This helps with creating local virtual environments, requirements,
# syntax checking, running tests, coverage and uploading packages to PyPI.
# 
# This also works with Travis CI
# For more information on creating packages for PyPI see the writeup at
# http://peterdowns.com/posts/first-time-with-pypi.html
#
.PHONY: help
help:
	@echo "env     Create virtualenv and install requirements"
	@echo "check   Run style checks"
	@echo "test    Run tests"
	@echo "pdb     Run tests, but stop at the first unhandled exception."
	@echo "upload  Upload package to PyPI"
	@echo "clean clean-all  Clean up and clean up removing virtualenv"
##############################################################################
PROJECT := Example
PACKAGE := example.py
# Replace 'requirements.txt' with another filename if needed.
REQUIREMENTS := $(wildcard requirements.txt)
# Directory with all the tests
TESTDIR := test
TESTREQUIREMENTS := $(wildcard $(TESTDIR)/requirements.txt)
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
BIN := $(ENV)/bin
OPEN := xdg-open
SYS_VIRTUALENV := virtualenv
SYS_PYTHON := python$(PYTHON_MAJOR)
ifdef PYTHON_MINOR
	SYS_PYTHON := $(SYS_PYTHON).$(PYTHON_MINOR)
endif

# virtualenv executables
PIP := $(BIN)/pip
PYTHON := $(BIN)/python
FLAKE8 := $(BIN)/flake8
PEP257 := $(BIN)/pep257
COVERAGE := $(BIN)/coverage
TESTRUN := $(BIN)/py.test

# Project settings
SETUP_PY := $(wildcard setup.py)
SOURCES := Makefile $(SETUP_PY) \
	       $(shell find $(PACKAGE) -name '*.py')
TESTS :=   $(shell find $(TESTDIR) -name '*.py')
EGG_INFO := $(subst -,_,$(PROJECT)).egg-info

# Flags for environment/tools
ALL := $(ENV)/.all
DEPENDS_CI := $(ENV)/.depends-ci
DEPENDS_DEV := $(ENV)/.depends-dev
# Main Targets ###############################################################
.PHONY: all env
all: env $(ALL)
$(ALL): $(SOURCES)
	$(MAKE) check
	@touch $@  # flag to indicate all setup steps were successful

# Targets to run on Travis
.PHONY: ci
ci: test

# Environment Installation ###################################################
env: $(PIP) $(ENV)/.requirements $(ENV)/.setup.py
$(PIP):
	$(SYS_VIRTUALENV) --python $(SYS_PYTHON) $(ENV)
	@$(MAKE) -s $(ENV)/.requirements
	@$(MAKE) -s $(ENV)/.setup.py

$(ENV)/.requirements: $(REQUIREMENTS)
ifneq ($(REQUIREMENTS),)
	$(PIP) install --upgrade -r requirements.txt
	@echo "Upgrade or install requirements.txt complete."
endif
	@touch $@

$(ENV)/.setup.py: $(SETUP_PY)
ifneq ($(SETUP_PY),)
	$(PIP) install -e .
endif
	@touch $@

### Static Analysis & Travis CI ##############################################
.PHONY: check flake8 pep257

PEP8_IGNORED := E501,E123,D104,D203
check: flake8 pep257

$(DEPENDS_CI): env $(TESTREQUIREMENTS)
	$(PIP) install --upgrade flake8 pep257
	@touch $@  # flag to indicate dependencies are installed

$(DEPENDS_DEV): env
	$(PIP) install --upgrade wheel  # pygments wheel
	@touch $@  # flag to indicate dependencies are installed

flake8: $(DEPENDS_CI)
	$(FLAKE8) $(PACKAGE) $(TESTDIR) --ignore=$(PEP8_IGNORED)

pep257: $(DEPENDS_CI)
	$(PEP257) $(PACKAGE) $(TESTDIR) --ignore=$(PEP8_IGNORED)

### Testing ##################################################################
.PHONY: test pdb coverage

TESTRUN_OPTS := --cov $(PACKAGE) \
			   --cov-report term-missing \
			   --cov-report html 

test: env $(DEPENDS_CI) $(TESTS) $(ENV)/requirements-test
	$(TESTRUN) $(TESTDIR)/*.py $(TESTRUN_OPTS)

pdb: env $(DEPENDS_CI) $(TEST) $(ENV)/requirements-test
	$(TESTRUN) $(TESTDIR)/*.py $(TESTRUN_OPTS) -x --pdb

$(ENV)/requirements-test: $(TESTREQUIREMENTS)
ifneq ($(TESTREQUIREMENTS),)
	$(PIP) install --upgrade -r $(TESTREQUIREMENTS)
	@echo "Testing requirements installed."
endif
	@touch $@

coverage: test
	$(COVERAGE) html
	$(OPEN) htmlcov/index.html

# Cleanup ####################################################################
.PHONY: clean clean-env clean-all .clean-build .clean-test .clean-dist

clean: .clean-dist .clean-test .clean-build
	@rm -rf $(ALL)

clean-env: clean
	@rm -rf $(ENV)

clean-all: clean clean-env

.clean-build:
#	@find -name $(PACKAGE).c -delete
	@find $(TESTDIR) -name '*.pyc' -delete
	@find $(TESTDIR) -name '__pycache__' -delete
	@rm -rf $(EGG_INFO)
	@rm -rf __pycache__

.clean-test:
	@rm -rf .coverage
#	@rm -f *.log

.clean-dist:
	@rm -rf dist build

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
