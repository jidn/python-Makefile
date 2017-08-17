#!/usr/bin/env sh
. ./helper.sh
magenta "## ALL tests"
sh ./environment.sh && sh ./checking.sh && sh ./coverage.sh && ./travis.sh
green "Success"
