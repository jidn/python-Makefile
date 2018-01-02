# This helps with creating local virtual environments, requirements,
# syntax checking, running tests, coverage and uploading packages to PyPI.
# Homepage at https://github.com/jidn/python-Makefile
#
# This also works with Travis CI
#
# PACKAGE = Source code directory or leave empty
PACKAGE =
# TESTDIR = Test directory or '.' for current directory
TESTDIR = tests
PROJECT :=
ENV = venv
# Override by putting on commandline:  python=python2.7
python = python
REQUIRE = requirements.txt
##############################################################################
ifdef TRAVIS
	ENV = $(VIRTUAL_ENV)
endif
# System paths
BIN := $(ENV)/bin
OPEN := xdg-open
SYS_VIRTUALENV := virtualenv

# virtualenv executables
PIP := $(BIN)/pip
TOX := $(BIN)/tox
PYTHON := $(BIN)/$(python)
ANALIZE := $(BIN)/pylint
COVERAGE := $(BIN)/coverage
TEST_RUNNER := $(BIN)/py.test

# Project settings
PKGDIR := $(or $(PACKAGE), ./)
REQUIREMENTS := $(shell find ./ -name $(REQUIRE))
REQUIREMENTS_LOG := .requirements.log
SOURCES := $(or $(PACKAGE), $(wildcard *.py))
ANALIZE_PKGS = pylint pydocstyle
TEST_CODE := $(wildcard $(TESTDIR)/*.py)
TEST_RUNNER_PKGS = pytest
COVERAGE_FILE = default.coveragerc
COVERAGE_PKGS = pytest-cov
COVERAGE_RC := $(wildcard $(COVERAGE_FILE))
COVER_ARG := --cov-report term-missing --cov=$(PKGDIR) \
	$(if $(COVERAGE_RC), --cov-config $(COVERAGE_RC))
EGG_INFO := $(subst -,_,$(PROJECT)).egg-info

# Flags for environment/tools

### Main Targets #############################################################
.PHONY: all env ci help
all: check test

# Target for Travis
ci: test

env: $(REQUIREMENTS_LOG)
$(PIP):
	$(info Remember to source new environment  [ $(ENV) ])
	test -d $(ENV) || $(SYS_VIRTUALENV) --python $(python) $(ENV)

$(REQUIREMENTS_LOG): $(PIP) $(REQUIREMENTS)
	for f in $(REQUIREMENTS); do \
	  $(PIP) install -r $$f | tee -a $(REQUIREMENTS_LOG); \
	done

help:
	@echo "env        Create virtual environment and install requirements"
	@echo "             python=PYTHON_EXE   interpreter to use, default=python"
	@echo "check      Run style checks 'pylint' and 'docstring'"
	@echo "test       TEST_RUNNER on '$(TESTDIR)'"
	@echo "             args=\"-x --pdb --ff\"  optional arguments"
	@echo "coverage   Get coverage information, optional 'args' like test"
	@echo "tox        Test against multiple versions of python"
	@echo "upload     Upload package to PyPI"
	@echo "clean clean-all  Clean up and clean up removing virtualenv"

### Static Analysis & Travis CI ##############################################
.PHONY: check pylint docstring
check: $(REQUIREMENTS_LOG) pylint docstring

pylint: $(ANALIZE)
	$(ANALIZE) $(SOURCES) $(TEST_CODE)

docstring:
	$(PYTHON) -m pydocstyle $(SOURCES) $(ARGS)
# I prefer the Google Style Python Docstrings

$(ANALIZE):
	$(PIP) install --upgrade $(ANALIZE_PKGS) | tee -a $(REQUIREMENTS_LOG)

### Testing ##################################################################
.PHONY: test coverage tox

test: $(REQUIREMENTS_LOG) $(TEST_RUNNER)
	$(TEST_RUNNER) $(args) $(TESTDIR)

$(TEST_RUNNER):
	$(PIP) install $(TEST_RUNNER_PKGS) | tee -a $(REQUIREMENTS_LOG)

coverage: $(REQUIREMENTS_LOG) $(COVERAGE) $(COVERAGE_FILE)
	$(TEST_RUNNER) $(args) $(COVER_ARG) $(TESTDIR)

$(COVERAGE_FILE):
ifeq ($(PKGDIR),./)
ifeq (,$(COVERAGE_RC))
	# If PKGDIR is root directory, ie code is not in its own directory
	# then you should use a .coveragerc file to remove the ENV directory
	# from the coverage search.  I'll auto generate one for you.
	$(info Rerun make to discover autocreated $(COVERAGE_FILE))
	@echo -e "[run]\nomit=$(ENV)/*" > $(COVERAGE_FILE)
	@cat $(COVERAGE_FILE)
	@exit 68
endif
endif

$(COVERAGE): $(PIP)
	$(PIP) install $(COVERAGE_PKGS) | tee -a $(REQUIREMENTS_LOG)

tox: $(TOX)
	$(TOX)

$(TOX): $(PIP)
	$(PIP) install tox | tee -a $(REQUIREMENTS_LOG)

### Cleanup ##################################################################
.PHONY: clean clean-env clean-all clean-build clean-test clean-dist

clean: clean-dist clean-test clean-build

clean-env: clean
	-@rm -rf $(ENV)
	-@rm -rf $(REQUIREMENTS_LOG)
	-@rm -rf .tox

clean-all: clean clean-env

clean-build:
	@find $(PKGDIR) -name '*.pyc' -delete
	@find $(PKGDIR) -name '__pycache__' -delete
	@find $(TESTDIR) -name '*.pyc' -delete 2>/dev/null || true
	@find $(TESTDIR) -name '__pycache__' -delete 2>/dev/null || true
	-@rm -rf $(EGG_INFO)
	-@rm -rf __pycache__

clean-test:
	-@rm -rf .cache
	-@rm -rf .coverage

clean-dist:
	-@rm -rf dist build

### Release ##################################################################
# For more information on creating packages for PyPI see the writeup at
# http://peterdowns.com/posts/first-time-with-pypi.html
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

### System Installation ######################################################
.PHONY: develop install download
# Is this section really needed?

develop:
	$(PYTHON) setup.py develop

install:
	$(PYTHON) setup.py install

download:
	$(PIP) install $(PROJECT)
