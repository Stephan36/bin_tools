#!/bin/bash
#set -x
KEY_PATH=$1
if [ ! -d $KEY_PATH ]; then
ARG_APK=$KEY_PATH
KEY_PATH=~/tools/sign_android/
else
ARG_APK=$2
fi
APK_NAME=`echo $ARG_APK |  sed 's/\.apk//'`
RAW_APK_NAME=`echo $ARG_APK | awk -F'/' '{print $NF}'`
OUT_APK_PATH=~/temp/
if [ ! -e $OUT_APK_PATH ]; then
    mkdir -p $OUT_APK_PATH
fi
#java -jar ~/tools/sign_android/signapk.jar ${KEY_PATH}/platform.x509.pem ${KEY_PATH}/platform.pk8 $APK_NAME.apk  ${OUT_APK_PATH}/${RAW_APK_NAME}
#java -jar ~/tools/sign_android/signapk.jar ${KEY_PATH}/shared.x509.pem ${KEY_PATH}/shared.pk8 $APK_NAME.apk  ${OUT_APK_PATH}/${RAW_APK_NAME}
java -jar ~/tools/sign_android/signapk.jar ${KEY_PATH}/testkey.x509.pem ${KEY_PATH}/testkey.pk8 $APK_NAME.apk  ${OUT_APK_PATH}/${RAW_APK_NAME}
RET=$?
if [ "$RET" == "0" ]
then
    echo -e "output\n${OUT_APK_PATH}/${RAW_APK_NAME}"
else
    echo "signed failed"
fi
#set +x
