#!/bin/bash
# What do I do?
# 1) unzip all apks' lib to $apk/lib
# 2) genrate $apk/Android.mk according to $apk
# 3) genrate apps.mk for define PRODUCT_PACKAGES

apps=`find * -maxdepth 0 -type d | cut -d/ -f2`

echo "# Auto genrate by genrate_makefile.sh, see README and genrate_makefile.sh for detail" > apps.mk
for app in $apps; do

    # unzip libs out
    cd $app
    if [ -e "lib" ]; then
        find -name "*.so"  | xargs rm
    fi
    unzip -W $app.apk "lib/**.so" 
    #mkdir -p lib_temp
    if [ -e "lib/armeabi/" ]; then
        echo "mv lib/armeabi/* lib/"
        mv lib/armeabi/* lib/
    fi
    if [ -e "lib/armeabi-v7a/" ]; then
        echo "mv lib/armeabi-v7a/* lib/"
        mv lib/armeabi-v7a/* lib/
    fi
    if [ -e "lib" ]; then
        echo "find lib/* -type d | xargs rm -rf"
        find lib/* -type d | xargs rm -rf
    fi
    cd -

    # generate $apk/Android.mk
    b_app=`echo $app | tr a-z A-Z`
    echo "# Auto genrate by genrate_makefile.sh, see README and genrate_makefile.sh for detail" > $app/Android.mk
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
    libs=`echo $libs`
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

    # general apps.mk for define PRODUCT_PACKAGES
cat >> apps.mk << EOF

# for $app
ifeq (\$(strip \$(CVTE_${b_app}_SUPPORT)), yes)
    PRODUCT_PACKAGES += $app $libs
endif
ifeq (\$(strip \$(CVTE_${b_app}_VENDOR_SUPPORT)), yes)
    PRODUCT_PACKAGES += $app $libs
endif
# for $app end

EOF
done

