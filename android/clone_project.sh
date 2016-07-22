#!/bin/bash

# check project
. build/envsetup.sh
clean=0
CODE_ROOT=`pwd`
if [ "$#" != "2" ]; then
    echo "usage: $0 BASE_PROJECT NEW_PROJECT"
    echo "or: $0 clean project"
    exit 1
fi

PROJECTS=`ls ${CODE_ROOT}/device/mikimobile/`
if [ "$1" == "clean" ]; then
    BASE_PROJECT=$2
    for p in $PROJECTS; do
        if [ "$BASE_PROJECT" == "$p" ]; then
            rm -rf kernel-3.18/arch/arm64/boot/dts/${BASE_PROJECT}.dts && rm -rf kernel-3.18/arch/arm64/configs/${BASE_PROJECT}_* && rm -rf vendor/mediatek/proprietary/bootable/bootloader/lk/target/${BASE_PROJECT}/ && rm -rf vendor/mediatek/proprietary/bootable/bootloader/lk/project/${BASE_PROJECT}.mk &&rm -rf vendor/mediatek/proprietary/bootable/bootloader/preloader/custom/${BASE_PROJECT}/ && rm -rf vendor/mediatek/proprietary/custom/${BASE_PROJECT} && rm -rf device/mikimobile/${BASE_PROJECT}/  && rm -rf vendor/mikimobile/libs/${BASE_PROJECT}
        fi
    done
    exit 0
fi

BASE_PROJECT=$1
NEW_PROJECT=$2


project_exist=0
for p in $PROJECTS; do
    if [ "$BASE_PROJECT" == "$p" ]; then
        project_exist=1
    fi
done

if [ "$project_exist" == "0" ]; then
    echo "$BASE_PROJECT is not exist"
    exit 1
fi

for p in $PROJECTS; do
    if [ "$NEW_PROJECT" == "$p" ]; then
        echo "$NEW_PROJECT already exist"
        exit 1
    fi
done
# check project done

# clone preloader
cd ${CODE_ROOT}
cd vendor/mediatek/proprietary/bootable/bootloader/preloader/custom/
#tdir="vendor/mediatek/proprietary/bootable/bootloader/preloader/custom/"
cp -r  ${BASE_PROJECT}   ${NEW_PROJECT}
mv  ${NEW_PROJECT}/${BASE_PROJECT}.mk  ${NEW_PROJECT}/${NEW_PROJECT}.mk
sed -i   s/${BASE_PROJECT}/${NEW_PROJECT}/g  ${NEW_PROJECT}/${NEW_PROJECT}.mk
 
# clone lk
cd ${CODE_ROOT}
cd vendor/mediatek/proprietary/bootable/bootloader/lk/
cp  project/${BASE_PROJECT}.mk   project/${NEW_PROJECT}.mk
cp -r  target/${BASE_PROJECT}   target/${NEW_PROJECT}
sed -i   s/${BASE_PROJECT}/${NEW_PROJECT}/g    project/${NEW_PROJECT}.mk
 
# clone kernel
cd ${CODE_ROOT}
cd kernel-3.18/
# mt6755以及下面的arm64需要根据您的平台对应修改
#cp  -r  drivers/misc/mediatek/mach/mt6755/${BASE_PROJECT}   drivers/misc/mediatek/mach/mt6755/${NEW_PROJECT}
cp  arch/arm64/configs/${BASE_PROJECT}_defconfig   arch/arm64/configs/${NEW_PROJECT}_defconfig
cp  arch/arm64/configs/${BASE_PROJECT}_debug_defconfig   arch/arm64/configs/${NEW_PROJECT}_debug_defconfig  
sed  -i  s/${BASE_PROJECT}/${NEW_PROJECT}/g  arch/arm64/configs/${NEW_PROJECT}_defconfig
sed  -i  s/${BASE_PROJECT}/${NEW_PROJECT}/g  arch/arm64/configs/${NEW_PROJECT}_debug_defconfig
cp  arch/arm64/boot/dts/${BASE_PROJECT}.dts   arch/arm64/boot/dts/${NEW_PROJECT}.dts
 
#clone android
cd ${CODE_ROOT}
COMPANY=mikimobile
cp  -r  device/${COMPANY}/${BASE_PROJECT}   device/${COMPANY}/${NEW_PROJECT}
mv device/${COMPANY}/${NEW_PROJECT}/full_${BASE_PROJECT}.mk device/${COMPANY}/${NEW_PROJECT}/full_${NEW_PROJECT}.mk
cp  -r  vendor/mediatek/proprietary/custom/${BASE_PROJECT}  vendor/mediatek/proprietary/custom/${NEW_PROJECT}
if [ -f vendor/mediatek/proprietary/trustzone/custom/build/project/${BASE_PROJECT}.mk ]; then
    cp -fr vendor/mediatek/proprietary/trustzone/custom/build/project/${BASE_PROJECT}.mk vendor/mediatek/proprietary/trustzone/custom/build/project/${NEW_PROJECT}.mk
fi
cp -fr vendor/${COMPANY}/libs/${BASE_PROJECT} vendor/${COMPANY}/libs/${NEW_PROJECT}
sed -i s/${BASE_PROJECT}/${NEW_PROJECT}/g device/${COMPANY}/${NEW_PROJECT}/AndroidProducts.mk
sed -i  s/${BASE_PROJECT}/${NEW_PROJECT}/g  device/${COMPANY}/${NEW_PROJECT}/BoardConfig.mk
sed -i  s/${BASE_PROJECT}/${NEW_PROJECT}/g  device/${COMPANY}/${NEW_PROJECT}/device.mk
sed -i  s/${BASE_PROJECT}/${NEW_PROJECT}/g  device/${COMPANY}/${NEW_PROJECT}/full_${NEW_PROJECT}.mk
sed -i  s/${BASE_PROJECT}/${NEW_PROJECT}/g  device/${COMPANY}/${NEW_PROJECT}/vendorsetup.sh
sed -i s/${BASE_PROJECT}/${NEW_PROJECT}/g  vendor/mediatek/proprietary/custom/${NEW_PROJECT}/security/efuse/input.xml
sed -i s/${BASE_PROJECT}/${NEW_PROJECT}/g vendor/mediatek/proprietary/custom/${NEW_PROJECT}/Android.mk

echo "clone project done"
