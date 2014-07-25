#!/bin/bash

# NOTES: Before add new project, please create new folder(name after project) in \\172.18.44.242\SWrelease.
# It's used for save solfware package
BUILD_PROJECTS="ASBIS_PMT5777_3G"
#BUILD_PROJECTS="cvte_752h cvte_752j htt_8382_812h htt_8382_712h cvte_852h cvte_852j ASBIS_PMT5887_3G ASBIS_PMT5777_3G"
source /etc/profile
source /home/xjf/.bashrc
SRC_HOME=/home/xjf/mtk/pure/autobuild
PACKAGE_DIR=$SRC_HOME/dirImgPackage
IMAGES_DIR=$SRC_HOME/dirImgPackage

MAIN_OUPUT_LOG=$SRC_HOME/build.log
MAIN_ERROR_LOG=$SRC_HOME/error.log

set -e
cd $SRC_HOME
if [ -f $MAIN_OUPUT_LOG ]; then
    rm $MAIN_OUPUT_LOG
fi

if [ -f $MAIN_ERROR_LOG ]; then
    rm $MAIN_ERROR_LOG
fi

export USER=`whoami`
cd $SRC_HOME
# get last code
git pull > $MAIN_OUPUT_LOG 2> $MAIN_ERROR_LOG

echo "All projects:${BUILD_PROJECTS}" >> $MAIN_OUPUT_LOG
for BUILD_PROJECT in ${BUILD_PROJECTS}; do
    echo "build $BUILD_PROJECT .." >> $MAIN_OUPUT_LOG

    # clean
    rm -rf out

    OUPUT_LOG=$SRC_HOME/build_${BUILD_PROJECT}.log
    ERROR_LOG=$SRC_HOME/error_${BUILD_PROJECT}.log
    ## build command
    ./mk -o=TARGET_BUILD_VARIANT=user $BUILD_PROJECT new  > $OUPUT_LOG 2> $ERROR_LOG

    NOW=`date +"%Y-%m-%d"`
    COMMIT_ID=`git log -1 --pretty=format:"%h"`
    IMAGES_DIR="$PACKAGE_DIR/${BUILD_PROJECT}_${NOW}_${COMMIT_ID}"
    if [ ! -d $PACKAGE_DIR ]; then
        mkdir $PACKAGE_DIR
    fi
    ./movePackage.pl $IMAGES_DIR


    PACKAGE_NAME=${BUILD_PROJECT}_${NOW}_${COMMIT_ID}.zip
    cd ${IMAGES_DIR}
    zip -r ${PACKAGE_NAME} ./* 
    mv ${PACKAGE_NAME} ${PACKAGE_DIR}
    scp ${PACKAGE_DIR}/${PACKAGE_NAME} SWrelease@172.18.44.242:~/releaseImages/${BUILD_PROJECT}
    cd -
    rm -rf ${IMAGES_DIR}

    echo "build success" >> $OUPUT_LOG
    echo "build $BUILD_PROJECT success" >> $MAIN_OUPUT_LOG
done
echo "build all done" >> $MAIN_OUPUT_LOG
