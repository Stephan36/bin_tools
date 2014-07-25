#!/bin/bash

# NOTES: Before add new project, please create new folder(name after project) in swrelease@172.18.44.242:/home/swrelease/images/.
# It's used for save solfware package
#BUILD_PROJECTS="cvte_852h cvte_852j ASBIS_PMT5887_3G ASBIS_PMT5777_3G cvte_752j  cvte_752h ASBIS_PMT5887_3G_DT_PL"
# every 2/3/4 days for one build by projects.
TWO_DAY_PROJECTS="cvte_852j ASBIS_PMT5887_3G ASBIS_PMT5777_3G cvte_752h"
THREE_DAY_PROJECTS="cvte_752j cvte_852h"
FOUR_DAY_PROJECTS="ASBIS_PMT5887_3G_DT_PL"
source /etc/profile
source /home/xjf/.bashrc
SRC_HOME=/home/xjf/mtk/pure/autobuild
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
git pull origin master:master > $MAIN_OUPUT_LOG 2> $MAIN_ERROR_LOG
CURRENT_TIME=`date +'%s'`
LAST_GIT_TIME=`git log -1 --pretty=%ct`

echo "Current:         `date +'%F %T'`      ($CURRENT_TIME)" >> $MAIN_OUPUT_LOG
echo "Last git commit: `git log -1 --pretty=%ci`($LAST_GIT_TIME)" >> $MAIN_OUPUT_LOG

DELTA=`expr $CURRENT_TIME - $LAST_GIT_TIME`
echo "DELTA = $DELTA(`git log -1 --pretty=%cr`)" >> $MAIN_OUPUT_LOG

# Don't need to build.
# 172800->2days, 86400->1day
#if [ $DELTA -gt 172800 ]; then
    #echo "There is no commit in 2days, DON'T NEEN TO BUILD!!" >> $MAIN_OUPUT_LOG
    #exit 0
#fi


# Get projects need to build
BUILD_PROJECTS=""
THIS_DAY=`date +'%j'`
echo "THIS_DAY=$THIS_DAY"
TWO_DAY=`expr $THIS_DAY % 2`
echo "TWO_DAY=$TWO_DAY"
if [ "$TWO_DAY" == "0" ]; then
    BUILD_PROJECTS+=$TWO_DAY_PROJECTS
fi
THREE_DAY=`expr $THIS_DAY % 3`
echo "THREE_DAY=$THREE_DAY"
if [ "$THREE_DAY" == "0" ]; then
    BUILD_PROJECTS+=$THREE_DAY_PROJECTS
fi
FOUR_DAY=`expr $THIS_DAY % 4`
echo "FOUR_DAY=$FOUR_DAY"
if [ "$FOUR_DAY" == "0" ]; then
    BUILD_PROJECTS+=$FOUR_DAY_PROJECTS
fi
echo "All projects:${BUILD_PROJECTS}" >> $MAIN_OUPUT_LOG

# Start to build
for BUILD_PROJECT in ${BUILD_PROJECTS}; do
    echo "[`date +'%F %T'`]build $BUILD_PROJECT .." >> $MAIN_OUPUT_LOG

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
    scp ${PACKAGE_DIR}/${PACKAGE_NAME} swrelease@172.18.44.242:/home/swrelease/images/${BUILD_PROJECT}
    #mkdir -p /home/xjf/mtk_images/${BUILD_PROJECT}
    #mv ${PACKAGE_DIR}/${PACKAGE_NAME}  /home/xjf/mtk_images/${BUILD_PROJECT}/
    rm -f ${PACKAGE_DIR}/${PACKAGE_NAME}
    cd -
    rm -rf ${IMAGES_DIR}

    echo "[`date +'%F %T'`]build success" >> $OUPUT_LOG
    echo "[`date +'%F %T'`]build $BUILD_PROJECT success" >> $MAIN_OUPUT_LOG
done
echo "build all done" >> $MAIN_OUPUT_LOG
