# This helps with creating local virtual environments, requirements,
# syntax checking, running tests, coverage and uploading packages to PyPI.
# Homepage at https://github.com/jidn/python-Makefile
#
# This also works with Travis CI
#
# PACKAGE = Source code directory or leave empty
PACKAGE =
TESTDIR = tests
PROJECT :=
ENV = venv
# Override by putting on commandline:  python=python2.7
python = python
REQUIRE = requirements.txt
PEP8_IGNORE := E501,E123
PEP257_IGNORE := D104,D203
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
PEP257 := $(BIN)/pydocstyle
COVERAGE := $(BIN)/coverage
TEST_RUNNER := $(BIN)/py.test
$(TEST_RUNNER): env
	$(PIP) install pytest | tee -a $(LOG_REQUIRE)

# Project settings
PKGDIR := $(or $(PACKAGE), ./)
REQUIREMENTS := $(shell find ./ -name $(REQUIRE))
SETUP_PY := $(wildcard setup.py)
SOURCES := $(or $(PACKAGE), $(wildcard *.py))
COVERAGE_RC := $(wildcard default.coveragerc)
ANALIZE_RC := $(wildcard default.pylintrc)
EGG_INFO := $(subst -,_,$(PROJECT)).egg-info
COVER_ARG := --cov-report term-missing --cov=$(PKGDIR) \
	$(if $(wildcard default.coveragerc), --cov-config default.coveragerc)

# Flags for environment/tools
LOG_REQUIRE := .requirements.log

### Main Targets #############################################################
.PHONY: all env ci help
all: check test

# Target for Travis
ci: test

env: $(PIP) $(LOG_REQUIRE)
$(PIP):
	$(info "Environment is $(ENV)")
	test -d $(ENV) || $(SYS_VIRTUALENV) --python $(python) $(ENV)

$(LOG_REQUIRE): $(REQUIREMENTS)
	for f in $(REQUIREMENTS); do \
	  $(PIP) install -r $$f | tee -a $(LOG_REQUIRE); \
	done
	touch $@

help:
	@echo "env        Create virtualenv and install requirements"
	@echo "             python=PYTHON_EXE   interpreter to use, default=python"
	@echo "check      Run style checks"
	@echo "test       TEST_RUNNER on '$(TESTDIR)'"
	@echo "             args=\"-x --pdb --ff\"  optional arguments"
	@echo "coverage   Get coverage information, optional 'args' like test"
	@echo "tox        Test against multiple versions of python"
	@echo "upload     Upload package to PyPI"
	@echo "clean clean-all  Clean up and clean up removing virtualenv"

### Static Analysis & Travis CI ##############################################
.PHONY: check pylint pep257
check: pylint pep257

$(ANALIZE): $(PIP)
	$(PIP) install --upgrade pylint pydocstyle | tee -a $(LOG_REQUIRE)

pylint: $(ANALIZE) $(ANALIZE_RC)
	$(ANALIZE) $(SOURCES) $(TESTDIR) --ignore=$(PEP8_IGNORE)

pep257: $(ANALIZE)
	$(PEP257) $(SOURCES) $(ARGS) --ignore=$(PEP257_IGNORE)

$(ANALIZE_RC):
	$(warning Missing project pylint configuration file default.pylintrc)

### Testing ##################################################################
.PHONY: test coverage tox

test: $(TEST_RUNNER)
	$(TEST_RUNNER) $(args) $(TESTDIR)

coverage: $(COVERAGE) default.coveragerc
	$(TEST_RUNNER) $(args) $(COVER_ARG) $(TESTDIR)

default.coveragerc:
ifeq ($(PKGDIR),./)
ifeq (,$(wildcard $(default.coveragerc)))
	# If PKGDIR is root directory, ie code is not in its own directory
	# then you should use a .coveragerc file to remove the ENV directory
	# from the coverage search.  I'll auto generate one for you.
	$(info Rerun make to discover autocreated .coveragerc)
	@echo -e "[run]\nomit=$(ENV)/*" > default.coveragerc
	@cat default.coveragerc
	@exit 68
endif
endif


$(COVERAGE): env
	$(PIP) install pytest-cov | tee -a $(LOG_REQUIRE)

tox: $(TOX)
	$(TOX)

$(TOX): $(PIP)
	$(PIP) install tox | tee -a $(LOG_REQUIRE)

### Cleanup ##################################################################
.PHONY: clean clean-env clean-all clean-build clean-test clean-dist

clean: clean-dist clean-test clean-build

clean-env: clean
	-@rm -rf $(ENV)
	-@rm -rf $(LOG_REQUIRE)
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
