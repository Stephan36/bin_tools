#!/bin/bash

BUILD_PROJECTS=M831G_B

source /etc/profile
source /home/xjf/.bashrc
SRC_HOME=/home/xjf/codes/marvell/daily_build/pxa988_1088
PACKAGE_DIR=$SRC_HOME/marvell/package
IMAGES_DIR=$SRC_HOME/marvell/Image/

OUPUT_LOG=$SRC_HOME/build.log
ERROR_LOG=$SRC_HOME/error.log
export USER=`whoami`

set -e
cd $SRC_HOME
if [ -f $SRC_HOME/build.log ]; then
    rm $SRC_HOME/build.log 
fi

if [ -f $SRC_HOME/build.err ]; then
    rm $SRC_HOME/build.err
fi

cd $SRC_HOME
# get last code
repo sync -q > $OUPUT_LOG 2> $ERROR_LOG

# clean
rm -rf out

# build command
. envsetup.sh >> $OUPUT_LOG
mkproduct -p ${BUILD_PROJECTS} -ft -d >> $OUPUT_LOG 2>> $ERROR_LOG

if [ ! -d $PACKAGE_DIR ]; then
    mkdir $PACKAGE_DIR
fi

# version code? git commit
LAST_COMMIT=`mkproduct -l | head -n 1`
VERSION=`echo $LAST_COMMIT | sed 's/]/ /g' | sed 's/\[//g' | awk '{print $4}'`
NOW=`date +"%Y-%m-%d"`
LAST_COMMIT_DATE=`echo $LAST_COMMIT | sed 's/]/ /g' | sed 's/\[//g' | awk '{print $1}'`
echo "NOW: $NOW, ,LAST: $LAST_COMMIT_DATE" >> $OUPUT_LOG
#if [ "$NOW" != "$LAST_COMMIT_DATE" ]; then
    #echo "No update...out" >> $OUPUT_LOG
    #exit 1
#fi


PACKAGE_NAME=${BUILD_PROJECTS}_${LAST_COMMIT_DATE}_${VERSION}.zip
cd ${IMAGES_DIR}/${BUILD_PROJECTS}/
zip -r ${PACKAGE_NAME} ./* 
cd -
mv ${IMAGES_DIR}/${BUILD_PROJECTS}/${PACKAGE_NAME} $PACKAGE_DIR
scp ${PACKAGE_DIR}/${PACKAGE_NAME} git_man@172.18.230.87:~/Project/Marvell/831g/

echo "build success" >> $OUPUT_LOG
