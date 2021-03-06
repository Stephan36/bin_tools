#!/bin/bash

# NOTES: Before add new project, please create new folder(name after project) in swrelease@172.18.44.242:/home/swrelease/images/.
# It's used for save solfware package
#BUILD_PROJECTS="cvte_852h cvte_852j ASBIS_PMT5887_3G ASBIS_PMT5777_3G cvte_752j  cvte_752h ASBIS_PMT5887_3G_DT_PL"
# every 2/3/4 days for one build by projects.
#ONE_DAY_PROJECTS="ASBIS_PMT5117_3G cvte_1051j cvte_1051j_full condor_1012h cvte_1012h TWINMOS_1055H "
#ONE_DAY_PROJECTS="datamatic_S4_3G ASBIS_PMT5117_3G cvte_1051j cvte_1012h condor_1012h"
#ONE_DAY_PROJECTS="cvte_1051j cvte_1051j_full cvte_1012h cvte_1012h_full cvte_852h cvte_852j"
#ONE_DAY_PROJECTS="cvte_1012h cvte_1051j cvte_752h cvte_752j cvte_852h cvte_852j cvte_1012hn cvte_1012h_full cvte_1012hn_full cvte_1051j_full cvte_1051jn cvte_1051jn_full"
TWO_DAY_PROJECTS="SmartCupboard_1051j"
#TWO_DAY_PROJECTS=" cvte_852j ASBIS_PMT5887_3G ASBIS_PMT5777_3G cvte_1051j_full"
#THREE_DAY_PROJECTS=" cvte_752j cvte_852h cvte_1051j TWINMOS_1055H "
#FOUR_DAY_PROJECTS=" ASBIS_PMT5887_3G_DT_PL cvte_752h "
source /etc/profile
source /home/xjf/.bashrc
export USE_DISTCC=true
export DISTCC_HOSTS=' 172.18.44.242 172.18.44.157 172.18.45.77 172.18.44.221 172.18.45.190 172.18.47.222 172.18.47.221'
#SRC_HOME=/home/xjf/mtk/pure/autobuild
SRC_HOME=/home/xjf/ssd/mt8382/SDK4.4.2
#SRC_HOME=/home/xjf/mtk/daily_build/SDK4.4.2
PACKAGE_DIR=$SRC_HOME/dirImgPackage
IMAGES_DIR=$SRC_HOME/dirImgPackage
OTA=no
PACKAGE_MP="-m"

LOG_DIR=$SRC_HOME/log
MAIN_OUPUT_LOG=$LOG_DIR/build.log
MAIN_ERROR_LOG=$LOG_DIR/error.log
mkdir -p $LOG_DIR
export USER=`whoami`

echo "" > $MAIN_OUPUT_LOG
function log {
    echo "$@" | tee -a $MAIN_OUPUT_LOG
}
set -e
cd $SRC_HOME
if [ -f $MAIN_OUPUT_LOG ]; then
    rm -rfv $MAIN_OUPUT_LOG
fi

if [ -f $MAIN_ERROR_LOG ]; then
    rm -rfv $MAIN_ERROR_LOG
fi

log "`date +%Y-%m-%d`: Start build mtk..."
cd $SRC_HOME
# get last code
git pull origin master > $MAIN_OUPUT_LOG 2> $MAIN_ERROR_LOG
CURRENT_TIME=`date +'%s'`
LAST_GIT_TIME=`git log -1 --pretty=%ct`

log "USE_DISTCC=$USE_DISTCC"
log "DISTCC_HOSTS=$DISTCC_HOSTS"
log "Current:         `date +'%F %T'`      ($CURRENT_TIME)"
log "Last git commit: `git log -1 --pretty=%ci`($LAST_GIT_TIME)"

DELTA=`expr $CURRENT_TIME - $LAST_GIT_TIME`
log "DELTA = $DELTA(`git log -1 --pretty=%cr`)"

# Don't need to build.
# 172800->2days, 86400->1day
#if [ $DELTA -gt 172800 ]; then
    #echo "There is no commit in 2days, DON'T NEEN TO BUILD!!" >> $MAIN_OUPUT_LOG
    #exit 0
#fi


# Get projects need to build
BUILD_PROJECTS=""
THIS_DAY=`date +'%j'`
let THIS_DAY=$THIS_DAY+1
log "THIS_DAY=$THIS_DAY"
TEST_LOG=`git log --since=1.day.ago`
if [ "$TEST_LOG" != "" ]; then
BUILD_PROJECTS+=" ${ONE_DAY_PROJECTS} "
fi

TWO_DAY=$(($THIS_DAY%2))
log "TWO_DAY=$TWO_DAY"
TEST_LOG=`git log --since=2.day.ago`
if [ "$TEST_LOG" != "" ]; then
    if [ "$TWO_DAY" == "0" ]; then
        log "TWO_DAY=$TWO_DAY"
        BUILD_PROJECTS+=$TWO_DAY_PROJECTS
    fi
fi

THREE_DAY=$(($THIS_DAY%3))
log "THREE_DAY=$THREE_DAY"
TEST_LOG=`git log --since=3.day.ago`
if [ "$TEST_LOG" != "" ]; then
    if [ "$THREE_DAY" == "0" ]; then
        BUILD_PROJECTS+=$THREE_DAY_PROJECTS
    fi
fi

FOUR_DAY=$(($THIS_DAY%4))
log "FOUR_DAY=$FOUR_DAY"
TEST_LOG=`git log --since=4.day.ago`
if [ "$TEST_LOG" != "" ]; then
    if [ "$FOUR_DAY" == "0" ]; then
        BUILD_PROJECTS+=$FOUR_DAY_PROJECTS
    fi
fi
log "All projects:${BUILD_PROJECTS}"

# Start to build
for BUILD_PROJECT in ${BUILD_PROJECTS}; do
    log "[`date +'%F %T'`]build $BUILD_PROJECT .."

    # clean
    rm -rf out

    OUPUT_LOG=$LOG_DIR/build_${BUILD_PROJECT}.log
    ERROR_LOG=$LOG_DIR/error_${BUILD_PROJECT}.log
    ## build command
    #if [ "cvte_1012h" == "$BUILD_PROJECT" ]; then
        #./mk -a -o=OTA=no $BUILD_PROJECT new  > $OUPUT_LOG 2> $ERROR_LOG
    #else
        ./mk -o=TARGET_BUILD_VARIANT=user,OTA=$OTA $BUILD_PROJECT new  > $OUPUT_LOG 2> $ERROR_LOG
    #fi

    NOW=`date +"%Y-%m-%d"`
    COMMIT_ID=`git log -1 --pretty=format:"%h"`
    IMAGES_DIR="$PACKAGE_DIR/${BUILD_PROJECT}_${NOW}_${COMMIT_ID}"
    if [ ! -d $PACKAGE_DIR ]; then
        mkdir $PACKAGE_DIR
    fi
    # signed images
    ./imgPackage.pl ${PACKAGE_MP} -d $IMAGES_DIR


    PACKAGE_NAME=${BUILD_PROJECT}_${NOW}_${COMMIT_ID}.zip
    cd ${IMAGES_DIR}
    rm -rf with_factory_test ota
    zip -r ${PACKAGE_NAME} ./* 
    mv ${PACKAGE_NAME} ${PACKAGE_DIR}
    scp ${PACKAGE_DIR}/${PACKAGE_NAME} swrelease@172.18.46.103:/home/swrelease/images/${BUILD_PROJECT}
    #mkdir -p /home/xjf/mtk_images/${BUILD_PROJECT}
    #mv ${PACKAGE_DIR}/${PACKAGE_NAME}  /home/xjf/mtk_images/${BUILD_PROJECT}/
    rm -rf ${PACKAGE_DIR}/${PACKAGE_NAME}
    cd -
    rm -rf ${IMAGES_DIR}

    log "[`date +'%F %T'`]build success"
    log "[`date +'%F %T'`]build $BUILD_PROJECT success"
done
log "build all done"
