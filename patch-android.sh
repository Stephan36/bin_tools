#!/bin/bash

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
PATCH_VERSION="[1.15.$1-android] [CL#"
for dir in `ls -d */ | sed 's/\///g'`; do
    #491201
    if [ ${dir} -lt 506117 ]; then
        continue
    fi
    cd ${CUR_PATH}
    echo -e "\033[36mPatch CL#${dir}...\033[0m"
    addfiles=`find ${dir}/currentVersion/ -type f | sed 's/.*currentVersion\/AEGIS\///' | tr '\n' ' '`
    delfiles=`sed -n '/Affected files/,$ p' ${dir}/${dir}_desciption.txt  | grep "delete$" | sed -n 's/.*\(android.*\)#.*delete/\1/ p'`
    desc=`cat ${dir}/${dir}_desciption.txt | sed -n '/\<Description\>/, /<\/Description>/ p' | sed 's/]]>//g' | sed  '/Description/ d' | sed 's/^\s\+//g' | tr '\n' ' '`
    cp ${dir}/currentVersion/AEGIS/android/ ${TO_PATH} -r
    echo "Log: ${desc}"
    cd ${TO_PATH}
    if [ -n "${delfiles}" ]; then
        temp_file=""
        for ff in ${delfiles}; do
            if [ -f ${ff} ]; then
                temp_file+="${ff} "
                #echo "${ff} exist"
            fi
        done
        #echo "need to rm ->>"
        #echo ${temp_file}
        delfiles=$temp_file
        if [ -n "${delfiles}" ]; then
            rm ${delfiles}
            git rm ${delfiles}
        fi
    fi
    echo "git add"
    git add ${addfiles}
    echo "git commit"
    #echo "git commit ${addfiles} -m \"${PATCH_VERSION}${dir}]\n\n${desc}\""
    #git commit ${addfiles} -m "${desc}"
    files="${addfiles} ${delfiles}"

git commit ${files} -F- << EOF
${PATCH_VERSION}${dir}]

${desc}
EOF

done

