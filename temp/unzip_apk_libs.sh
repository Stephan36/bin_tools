#!/bin/bash

apps=`ls "*.apk"`
for app in $apps; do
    mkdir -p $app
    if [ -e "lib" ]; then
        find -name "*.so"  | xargs rm
    fi
    unzip -W $app.apk "lib/**.so" 
    #mkdir -p lib_temp
    if [ -e "lib/armeabi/" ]; then
        echo "mv lib/armeabi/* lib/"
        mv lib/armeabi/* lib/
    fi
    if [ -e "lib/armeabi-v7a/" ]; then
        echo "mv lib/armeabi-v7a/* lib/"
        mv lib/armeabi-v7a/* lib/
    fi
    if [ -e "lib" ]; then
        echo "find lib/* -type d | xargs rm -rf"
        find lib/* -type d | xargs rm -rf
    fi
done
