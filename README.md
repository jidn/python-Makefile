In the attempt to create and use a standard Makefile for my python projects, this is the fruit of my labor.  It includes support for virtual environments, requirements, syntax checking, running tests, coverage and uploading packages to PyPI.  Why a Makefile instead of something modern?  Well because `make` is on every system I use and it does the job.

Travis CI is also supported, see the  `travis.yml`, but remember to change the name of the file as required to `.travis.yml` (adding a leading dot) for proper Travis CI working.

Copy this file

```
curl https://raw.githubusercontent.com/jidn/python-Makefile/master/Makefile > Makefile
```

and make the following changes:

 * _PACKAGE_ := myproject/  or empty if python files are in the same directory.
 * _PROJECT_ := MyProject
 * _REQUIRE_ := The file with required packages; defaults to requirements.txt
 * _TESTDIR_ := Default is current directory 'tests'

## Targets

### env
Create the virtual environment in `venv` directory within the current directory.  No stomping on other virtual environments in some global directory.  Let's keep everything local to make environment debugging easier.  This is also where all the requirements are installed.

You can specify the python interpreter version by adding python=PYTHON_EXE on the command-line.  This defaults to the current python interpreter.

Examples:
``` bash
    $ make env python=python2.7
    $ make env python=python3.4m
```

### check
Static code analysis using pylint, ignoring the virtual environment.

### test
Run all the tests in TESTDIR.  By default, I am using pytest, but you can fix this by changing TEST_RUNNER and TEST_RUNNER_PKGS.

You can also pass arguments to your TEST_RUNNER by adding `args=" ... "` on the command line.

Examples:
``` bash
    $ make test args="-v"
    $ make test args="-x --pdb --ff"
```

### coverage
It runs your tests observing if they execute the entire code base.  It then creates a terminal report with lines that missed coverage.  You can pass additional arguments to coverage use the `arg` command line just like in test.  To permanently change argument, modify the `COVER_ARG` argument in Makefile.

If `PACKAGE` is empty, python files are in the same directory as Makefile, you should use a coverage config file to omit the virtual environment directory from the coverage search.  In this case, Makefile will create a `default.coveragerc` file for you and then stop make execution.  When you rerun make it will find the `default.coveragerc` and append "--cov-config default.coveragerc" to `COVER_ARG`.

Here is the created `default.coveragerc` with a placeholder for your environment directory.

```
[run]
omit=${ENV}/*
```

### clean clean-all
The target clean removes everything but environment and clean-all removes the environment.

### upload
Package the module and upload it PyPI.

## Testing Makefile
To keep me from breaking functionality, I needed some testing scripts.  These tests both instances where source files are in the same directory as the Make file and where source files are in a separate directory.

  * _all.sh_: Run all the tests.
  * _environment.sh_: verify proper virtualenv creation by target **env**
  * _checking.sh_: verify static code analysis by target **check**
  * _coverage.sh_: verify testing and coverage working by target **coverage**
  * _travis.sh_: verify it works properly under Travis-ci.org environment

## Other files

### travis.yml
A simple `.travis.yml` for python versions 2.7, 3.3, 3.4, and 3.6 in continuous integration testing.  I am not using 3.5 as wheel is giving me some problems when compiling dependencies.  It is already set to use [coveralls](coveralls.io), so go to coveralls.io and hook up your project and travis-ci will send the run information for coverage analysis.

### .pypirc
The authentication file I use for uploading modules to PyPI.  Of course I have stripted out the username and passwords.

### gitignore
Here is the `.gitignore` file I use.  I am not sure about the source of inspiration, but I have been using this for quite awhile.
