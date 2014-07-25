#!/bin/bash

git status -uno -s . | cut -c3- | xargs git add 
