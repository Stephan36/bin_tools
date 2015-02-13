#!/bin/bash

for pkg in *.gz; do
    mkdir "${pkg}_dir"
    tar -xf "$pkg" -C "${pkg}_dir"
done
