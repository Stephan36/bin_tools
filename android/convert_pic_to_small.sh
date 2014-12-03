#!/bin/bash

pics=`find -iname "*.png" -o -iname "*.jpg"`

for pic in $pics; do
    pic_name=`echo $pic | cut -d. -f2 | cut -d/ -f2`
    set -x
    convert -resize 240 $pic ${pic_name}_small.jpg
    set +x
done
