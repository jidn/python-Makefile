#!/usr/bin/env sh
. ./helper.sh
magenata "## ALL tests"
sh ./environment.sh && sh ./checking.sh && sh ./coverage.sh && ./travis.sh
green "Success"
