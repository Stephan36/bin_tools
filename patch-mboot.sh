#!/bin/bash

# abc ef
# get patch message
# cat *_desciption.txt | sed -n '/\<Description\>/, /<\/Description>/ p' | sed 's/]]>//g' | sed  '/Description/ d'

# ls dir
# ls -d */ | sed 's/\///g'

if [ -z $1 ]; then
    echo no version input.
    echo "usage: mst-patch-xxx.sh [1,2...30]"
    exit 1
fi

CUR_PATH=`pwd`
TO_PATH=~/srcs/mstar/m/cvt-mst-code-build
#TO_PATH=~/test/gittest/
PATCH_PART=MBoot
PATCH_VERSION="[1.15.$1-${PATCH_PART}] [CL#"
for dir in `ls -d */ | sed 's/\///g'`; do
    # 498268
    #if [ ${dir} -le 498268 ]; then
        #continue
    #fi
    cd ${CUR_PATH}
    echo -e "\033[36mPatch CL#${dir}...\033[0m"
    cp -r ${dir}/currentVersion/DAILEO/MBoot_Branch/MBoot_Edison_TVOS/* ${TO_PATH}/MBoot/
    files=`find ${dir}/currentVersion/ -type f | sed 's/^.*MBoot_Edison_TVOS/MBoot/g' | tr '\n' ' '`
    #echo ${files}
    #test=test
    if [ -z $test ]; then
    desc=`cat ${dir}/${dir}_desciption.txt | sed -n '/\<Description\>/, /<\/Description>/ p' | sed 's/]]>//g' | sed  '/Description/ d' | sed 's/^\s\+//g'`
    echo "log: ${desc}"
    cd ${TO_PATH}
    echo "git add"
    git add ${files}
    echo "git commit"
    #echo "git commit ${files} -m \"${patch_version}${dir}]\n\n${desc}\""
    #git commit ${files} -m "${desc}"
git commit ${files} -F- << EOF
${PATCH_VERSION}${dir}]

${desc}
EOF
    fi

done

