#!/bin/bash

apps=`find * -maxdepth 0 -type d | cut -d/ -f2`

for app in $apps; do
    #set -x
    #sed 's/\<QQBrowser\>/'$app'/g' Android.mk > $app/Android.mk
    #b_app=`echo $app | tr a-z A-Z`
    #sed -i 's/\<QQBrowser_VENDOR\>/'$b_app'_VENDOR_SUPPORT/g' $app/Android.mk

    b_app=`echo $app | tr a-z A-Z`
    echo > $app/Android.mk
cat  >> $app/Android.mk << EOF
LOCAL_PATH := \$(call my-dir)
include \$(CLEAR_VARS)

# Module name should match apk name to be installed
LOCAL_MODULE := $app
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := \$(LOCAL_MODULE).apk
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_SUFFIX := \$(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_CERTIFICATE := PRESIGNED
ifeq (\$(CVTE_${b_app}_VENDOR_SUPPORT), yes)
LOCAL_MODULE_PATH := \$(TARGET_OUT)/vendor/operator/app
else
LOCAL_MODULE_PATH := \$(TARGET_OUT)/app
endif
include \$(BUILD_PREBUILT)

EOF
    #set +x
    libs=`ls $app/lib/`
    for lib in $libs; do
cat >> $app/Android.mk << EOF

include \$(CLEAR_VARS)
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE := $lib
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_SRC_FILES := lib/\$(LOCAL_MODULE)
LOCAL_MODULE_PATH := \$(TARGET_OUT)/lib
include \$(BUILD_PREBUILT)

EOF
    done
done
