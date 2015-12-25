#!/bin/bash

pics=`find -iname "*.png" -o -iname "*.jpg"`

for pic in $pics; do
    pic_name=`basename $pic | awk -F. '{print $1}'`
    path=`dirname $pic`
    set -x
    #convert -resize 600 $pic ${path}/${pic_name}_thumb.jpg
    #convert -resize 600 $pic ${path}/${pic}
    #convert -resize 560 $pic ${path}/${pic}
    #convert -resize 450 $pic ${path}/${pic}
    convert -resize 560 $pic ${pic}
    set +x
done
