#!/bin/bash

if [ "$#" == "0" ]; then
    ARGS="."
else
    ARGS="$@"
fi
set -x
ctags -R --c++-kinds=+p --fields=+ialS --extra=+q $ARGS
