In the attempt to create and use a standard Makefile for my python projects, this is the fruit of my labor.  It includes support for virtual environments, requirements, syntax checking, running tests, coverage and uploading packages to PyPI.  Why a Makefile instead of something modern?  Well because `make` is on every system I use and it does the job.

Travis CI is also supported, see the  `travis.yml`, but remember to change the name of the file as required to `.travis.yml` (adding a leading dot) for proper Travis CI working.

Copy this file

```
curl https://raw.githubusercontent.com/jidn/python-Makefile/master/Makefile > Makefile
```

and make the following changes:

 * _PROJECT_ := MyProject
 * _PACKAGE_ := myproject/  or myproject.py
 * _REQUIRE_ := The file with required packages; defaults to requirements.txt
 * _TESTDIR_ := Default is current directory 'tests'

## Targets

### env
Create the virtual environment in `.env` directory within the current directory.  No stomping on other virtual environments in some global directory.  Lets keep everything local to make environment debugging easier.  This is also where all the requirements are installed.

You can specify the python interpreter version by adding python=PYTHON_EXE on the command-line.  This defaults to the current python interpreter.

Examples:
``` bash
    $ make env python=python2.7
    $ make env python=python3.4m
```

### check
Static code analysis using flake8, ignoring the virtual environment and test directory.

### test
Run all the tests in TESTDIR.  By default, I am using pytest, but you can fix this by changing TEST_RUNNER.

You can also pass arguments to your TEST_RUNNER by adding `args=" ... "` on the command line.

Examples:
``` bash
    $ make test args="-v"
    $ make test args="-x --pdb --ff"
```

### coverage
It does the same as test and additionally creates a terminal report with lines that missed coverage.  You can pass additional arguments to coverage use the `arg` command line just like in test.  To permanently change argument, modify the _COVERAGE_ argument in Makefile.

### clean clean-all
The target clean removes everything but environment and clean-all removes the environment.

### coverage
Check the coverage and show the text output.  It also creates the HTML output.

### upload
Package the module and upload it PyPI.

## Other files

### travis.yml
A simple `.travis.yml` for python versions 2.7, 3.2, 3.3, and 3.4 in continuous integration testing.  I am not using 3.5 as wheel is giving me some problems when compiling dependencies.

### create_Makefile.sh
It appears I am finding bugs as I go along and use this for existing projects.  I make the fixes for the project, port it back here, then copy the new Makefile from this project back to the existing project.  This helps automate the task while also showing how to make changes to the Makefile.

### .pypirc
The authentication file I use for uploading modules to PyPI.  Of course I have stripted out the username and passwords.

### gitignore
Here is the `.gitignore` file I use.  I am not sure about the source of inspiration, but I have been using this for quite awhile.

## Testing Makefile
To keep me from breaking functionality, I needed some testing scripts.  I am including there to test
  * _environment.sh_: verify proper virtualenv creation by target **env**
  * _checking.sh_: verify static code analysis by target **check**
  * _coverage.sh_: verify testing and coverage working by target **coverage**
