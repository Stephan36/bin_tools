#!/bin/bash

# check project
clean=0
if [ "$#" != "2" ]; then
    echo "usage: $0 BASE_PROJECT NEW_PROJECT"
    echo "or: $0 clean project"
    exit 1
fi

PROJECTS=$(perl mediatek/build/tools/listP.pl)
if [ "$1" == "clean" ]; then
    BASE_PROJECT=$2
    for p in $PROJECTS; do
        if [ "$BASE_PROJECT" == "$p" ]; then
            set -x
            rm -rfv mediatek/config/$BASE_PROJECT/
            rm -rfv mediatek/custom/$BASE_PROJECT/
            rm -rfv build/target/product/$BASE_PROJECT.mk
            rm -rfv bootable/bootloader/lk/project/$BASE_PROJECT.mk
            rm -rfv vendor/mediatek/$BASE_PROJECT/
            rm -rfv mediatek/binary/packages/$BASE_PROJECT/
            set +x
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

PWD=`pwd`

# clone preloader
cd ${PWD}
cd vendor/mediatek/proprietary/bootable/bootloader/preloader/custom/
#tdir="vendor/mediatek/proprietary/bootable/bootloader/preloader/custom/"
cp -r  ${BASE_PROJECT}   ${NEW_PROJECT}
 mv  ${NEW_PROJECT}/${BASE_PROJECT}.mk  ${NEW_PROJECT}/${NEW_PROJECT}.mk
sed -i   s/${BASE_PROJECT}/${NEW_PROJECT}/g  ${NEW_PROJECT}/${NEW_PROJECT}.mk
 
# clone lk
cd ${PWD}
cd vendor/mediatek/proprietary/bootable/bootloader/lk/
cp  project/${BASE_PROJECT}.mk   project/${NEW_PROJECT}.mk
cp -r  target/${BASE_PROJECT}   target/${NEW_PROJECT}
sed -i   s/${BASE_PROJECT}/${NEW_PROJECT}/g    project/${NEW_PROJECT}.mk
 
# clone kernel
cd ${PWD}
cd kernel-3.18/
cp  -r  drivers/misc/mediatek/mach/mt6755/${BASE_PROJECT}   drivers/misc/mediatek/mach/mt6755/${NEW_PROJECT}   // mt6755以及下面的arm64需要根据您的平台对应修改
cp  arch/arm64/configs/${BASE_PROJECT}_defconfig   arch/arm64/configs/${NEW_PROJECT}_defconfig
cp  arch/arm64/configs/${BASE_PROJECT}_debug_defconfig   arch/arm64/configs/${NEW_PROJECT}_debug_defconfig  
sed  -i  s/${BASE_PROJECT}/${NEW_PROJECT}/g  arch/arm64/configs/${NEW_PROJECT}_defconfig
sed  -i  s/${BASE_PROJECT}/${NEW_PROJECT}/g  arch/arm64/configs/${NEW_PROJECT}_debug_defconfig
cp  arch/arm64/boot/dts/${BASE_PROJECT}.dts   arch/arm64/boot/dts/${NEW_PROJECT}.dts
 
#clone android
cd ${PWD}
cp  -r  device/${COMPANY}/${BASE_PROJECT}   device/${COMPANY}/${NEW_PROJECT}
mv  device/${COMPANY}/${NEW_PROJECT}/full_${BASE_PROJECT}.mk  device/${COMPANY}/ ${NEW_PROJECT}/full_${NEW_PROJECT}.mk
cp  -r  vendor/mediatek/proprietary/custom/${BASE_PROJECT}  vendor/mediatek/proprietary/custom/${NEW_PROJECT}
cp  vendor/mediatek/proprietary/trustzone/custom/build/project /${BASE_PROJECT}.mk vendor/mediatek/proprietary/trustzone/custom/build/project /${NEW_PROJECT }.mk
cp –r vendor/${COMPANY}/libs/${BASE_PROJECT} vendor/${COMPANY}/libs/${NEW_PROJECT}
sed -i s/${BASE_PROJECT}/${NEW_PROJECT}/g device/${COMPANY}/${NEW_PROJECT}/AndroidProducts.mk
sed -i  s/${BASE_PROJECT}/${NEW_PROJECT}/g  device/${COMPANY}/${NEW_PROJECT}/BoardConfig.mk
sed -i  s/${BASE_PROJECT}/${NEW_PROJECT}/g  device/${COMPANY}/${NEW_PROJECT}/device.mk
sed -i  s/${BASE_PROJECT}/${NEW_PROJECT}/g  device/${COMPANY}/${NEW_PROJECT}/full_${NEW_PROJECT}.mk
sed -i  s/${BASE_PROJECT}/${NEW_PROJECT}/g  device/${COMPANY}/${NEW_PROJECT}/vendorsetup.sh
sed -i s/${BASE_PROJECT}/${NEW_PROJECT}/g  vendor/mediatek/proprietary/custom/${NEW_PROJECT}/security/efuse/input.xml
sed -i s/${BASE_PROJECT}/${NEW_PROJECT}/g vendor/mediatek/proprietary/custom/${NEW_PROJECT}/Android.mk

echo "clone project done"
