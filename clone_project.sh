#!/bin/bash

clean=0
if [ "$#" != "2" ]; then
    echo "usage: $0 src_project dst_project"
    echo "or: $0 clean project"
    exit 1
fi

PROJECTS=$(perl mediatek/build/tools/listP.pl)
if [ "$1" == "clean" ]; then
    src_project=$2
    for p in $PROJECTS; do
        if [ "$src_project" == "$p" ]; then
            set -x
            rm -rf mediatek/config/$src_project/
            rm -rf mediatek/custom/$src_project/
            rm -rf build/target/product/$src_project.mk
            rm -rf bootable/bootloader/lk/project/$src_project.mk
            rm -rf vendor/mediatek/$src_project/
            rm -rf mediatek/binary/packages/$src_project/
            set +x
        fi
    done
    exit 0
fi

src_project=$1
dst_project=$2


project_exist=0
for p in $PROJECTS; do
    if [ "$src_project" == "$p" ]; then
        project_exist=1
    fi
done

if [ "$project_exist" == "0" ]; then
    echo "$src_project is not exist"
    exit 1
fi

for p in $PROJECTS; do
    if [ "$dst_project" == "$p" ]; then
        echo "$dst_project already exist"
        exit 1
    fi
done

set -x
cp -a mediatek/config/$src_project/ mediatek/config/$dst_project
cp -a mediatek/custom/$src_project/ mediatek/custom/$dst_project
cp -a build/target/product/$src_project.mk build/target/product/$dst_project.mk
cp -a bootable/bootloader/lk/project/$src_project.mk bootable/bootloader/lk/project/$dst_project.mk
cp -a vendor/mediatek/$src_project/ vendor/mediatek/$dst_project
rm -a vendor/mediatek/$src_project/artifacts/out/target/product/$src_project/
cp -a vendor/mediatek/$src_project/artifacts/out/target/product/$src_project/ vendor/mediatek/$dst_project/artifacts/out/target/product/$dst_project
cp -a mediatek/binary/packages/$src_project/ mediatek/binary/packages/$dst_project
sed -i "s/\<$src_project\>/$dst_project/g" vendor/mediatek/$dst_project/artifacts/target.txt

set +x
