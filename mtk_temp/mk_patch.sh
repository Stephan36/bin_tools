#!/bin/bash


projects=`./mk listp`
patch_files=`git status -s vendor/mediatek/ | cut -c 3-`
#patch_files=`git diff  HEAD^...HEAD --numstat  vendor/mediatek/cvt82_tb_kk/  | awk '{print $3}'`
#set -x
for pr in $projects; do
    if [ "banyan_addon_x86" == "$pr" ]; then
        continue
    fi
    for file in $patch_files; do
        if [ "cvt82_tb_kk" == "$file" ]; then
            continue
        fi
        to_file=`echo $file | sed 's/cvt82_tb_kk/'${pr}'/g'`
        #echo "to_file: $to_file"
        #cp -va $file $to_file
        cp -a $file $to_file
    done
done

#set +x
