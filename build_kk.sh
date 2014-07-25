#!/bin/bash

# NOTES: Before add new project, please create new folder(name after project) in \\172.18.44.242\SWrelease.
# It's used for save solfware package
#BUILD_PROJECTS="cvte_752h cvte_752j cvte_852h cvte_852j ASBIS_PMT5887_3G ASBIS_PMT5777_3G"
#BUILD_PROJECTS="cvte_852j cvte_752h cvte_752j cvte_852h ASBIS_PMT5887_3G ASBIS_PMT5777_3G"
BUILD_PROJECTS="cvte_752j cvte_852h cvte_852j"
source /etc/profile
source /home/xjf/.bashrc
#SRC_HOME=/home/xjf/mtk/pure/autobuild
SRC_HOME=/home/xjf/mtk/aging/SDK4.4.2
PACKAGE_DIR=$SRC_HOME/dirImgPackage
IMAGES_DIR=$SRC_HOME/dirImgPackage

MAIN_OUPUT_LOG=$SRC_HOME/build.log
MAIN_ERROR_LOG=$SRC_HOME/error.log

export USER=`whoami`
set -e
cd $SRC_HOME
if [ -f $MAIN_OUPUT_LOG ]; then
    rm $MAIN_OUPUT_LOG
fi

if [ -f $MAIN_ERROR_LOG ]; then
    rm $MAIN_ERROR_LOG
fi

cd $SRC_HOME
# get last code
git pull > $MAIN_OUPUT_LOG 2> $MAIN_ERROR_LOG

URRENT_TIME=`date +'%s'`
LAST_GIT_TIME=`git log -1 --pretty=%ct`

echo "Current:         `date +'%F %T'`      ($CURRENT_TIME)"
echo "Last git commit: `git log -1 --pretty=%ci`($LAST_GIT_TIME)"

DELTA=`expr $CURRENT_TIME - $LAST_GIT_TIME`
echo "DELTA = $DELTA(`git log -1 --pretty=%cr`)"

if [ $DELTA -gt 172800]; then
    echo "There is no commit in 2days, don't need to build"
    exit 0
fi

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
    # signed images
    ./imgPackage.pl -d $IMAGES_DIR


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
