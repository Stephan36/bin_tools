#!/bin/bash

# setup jdk
. /opt/change_jdk 1.7 2>&1 /dev/null
. build/envsetup.sh
CODE_ROOT=`pwd`
if [ ! -d out ]; then
    mkdir -p out
fi
. info.sh

export PRE_PROJECT=$PRE_PROJECT
JOBS=`cat /proc/cpuinfo  | grep -w processor | wc -l`
PROJECT=$PRE_PROJECT
BUILD_PART="all"
BUILD_FORCE=""
BUILD_OTA="no"

O_ARGS="-p -r -t -o"

BUILD_OTA=no
IMAGE_DIR=
MTK_TARGET_PROJECT=
PROJECT_OUT=${OUT}

function build_ota()
{
    build_time=`date +%s`
    echo "make otapackage $build_time"
    ota_file=
    make -j${JOBS} otapackage
    for file in `ls ${PROJECT_OUT}/*${MTK_TARGET_PROJECT}*.zip`; do
        file_time=`basename $file | awk -F. '{print $1}' | awk -F- '{print $NF}'`
        #echo "file[$file]: $file_time"
        if [ $file_time -ge $build_time ]; then
            ota_file=$file
            build_time=$file_time
            break;
        fi
    done
    if [ -f $ota_fiel ]; then
        cp -v $ota_file $IMAGE_DIR
        cp -v ${OUT}/obj/PACKAGING/target_files_intermediates/${TARGET_PRODUCT}-target_files-${build_time}.zip $IMAGE_DIR
    fi
}

function mk()
{
    # -p $project
    # -r, fore build
    # -o, full build with otapackage
    # -t $part,  kernel | lk | preloader | boot
    unset OPTIND
    while getopts "p:rot:" arg
    do
        case $arg in
            p)
                PROJECT="$OPTARG"
                ;;
            t)
                BUILD_PART="$OPTARG"
                ;;
            r)
                BUILD_FORCE="-B"
                ;;
            o)
                BUILD_OTA="yes"
                ;;

            ?)  
                echo "unkonw argument: $OPTIND"
                exit 1
                ;;
        esac
    done

    MTK_TARGET_PROJECT=`echo ${PROJECT} | sed 's/\(full_\|-eng\|-user\|-userdebug\)//g'`
    if [[ $PROJECTS =~ .*$PROJECT.* ]]; then
        echo "Start build $PROJECT $BUILD_PART"
    else
        echo -e ""
        echo -e "\033[031m$PROJECT is not found!\033[0m"
        exit 1
    fi

    #echo $MTK_TARGET_PROJECT
    #echo "project ${PROJECT}"
    #return 0

    if [[ "${PRE_PROJECT}" == "" ]] || [[ "${PRE_PROJECT}" != "${PROJECT}" ]]; then
        echo "lunch $PROJECT"
        lunch ${PROJECT}
        PRE_PROJECT=$PROJECT
    fi
    PROJECT_OUT=$OUT


    IMAGE_DIR="${CODE_ROOT}/result/${MTK_TARGET_PROJECT}-${TARGET_BUILD_VARIANT}"
    mkdir -p $IMAGE_DIR 
    if [[ $BUILD_PART == "kernel" ]]; then
        mmm ${BUILD_FORCE} kernel-3.18:kernel -j${JOBS}
    elif [[ $BUILD_PART == "lk" ]]; then
        mmm ${BUILD_FORCE} vendor/mediatek/proprietary/bootable/bootloader/lk:lk -j${JOBS}
        cp -v ${OUT}/lk.bin $IMAGE_DIR
    elif [[ $BUILD_PART == "preloader" ]]; then
        mmm ${BUILD_FORCE} vendor/mediatek/proprietary/bootable/bootloader/preloader:pl -j${JOBS}
        cp -v ${OUT}/preloader_${MTK_TARGET_PROJECT}.bin $IMAGE_DIR
    elif [[ $BUILD_PART == "boot" ]]; then
        make -j${JOBS} ramdisk-nodeps
        make -j${JOBS} bootimage-nodeps
        cp -v ${OUT}/boot.img $IMAGE_DIR
    elif [[ $BUILD_PART == "otapackage" ]]; then
        build_ota
    elif [[ $BUILD_PART == "systemimage" ]]; then
        make -j${JOBS} systemimage
        cp -v ${OUT}/system.img $IMAGE_DIR
    elif [[ $BUILD_PART == "bootimage" ]]; then
        make -j${JOBS} bootimage
        cp -v ${OUT}/boot.img $IMAGE_DIR
    elif [[ $BUILD_PART == "snod" ]]; then
        make -j${JOBS} snod
        cp -v ${OUT}/system.img $IMAGE_DIR
    else
        temp_file=$IMAGE_DIR/git
        echo "" > $temp_file
        repo forall -c "git log -1 --pretty=format:\"%h:\$REPO_PATH %n\"" >> $temp_file
        mkdir -p ${OUT}/system/etc/
        cp $temp_file ${OUT}/system/etc/log

        make -j${JOBS} 2>&1 | tee out/build.log

        if [[ "${BUILD_OTA}" == "yes" ]]; then
            build_ota
        fi
        
        SCATTER_FILE=${OUT}/MT8163_Android_scatter.txt
        index=0
        cp -v $SCATTER_FILE $IMAGE_DIR
        for image in `grep file_name $SCATTER_FILE | awk '{print $2}'`; do
            let index+=1
            if [[ "NONE" == "$image" ]]; then
                continue
            fi
            grep is_download $SCATTER_FILE | awk '{print $2}' | sed -n ''${index}'p'
            if [[ "true" == `grep is_download $SCATTER_FILE | awk '{print $2}' | sed -n ''${index}'p'` ]]; then
                cp -v ${OUT}/${image} $IMAGE_DIR
            fi
        done



    fi

    echo -e ""
    echo -e "\033[032mbuild done!\033[0m"

    return 0
}

function _build()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    ARGS=${O_ARGS}
    index=0
    while [ $index -lt $COMP_CWORD ]; do
        ARGS=${ARGS/${COMP_WORDS[index]}/}
        let index+=1
    done

    case $prev in
        #mk)
            #COMPREPLY=( $(compgen -W "-p" -- ${cur}) )
            #;;
        -p)
            COMPREPLY=( $(compgen -W "${PROJECTS}" -- ${cur}) )
            ;;
        #-r) 
            #ARGS=${ARGS/\-r/}
            #COMPREPLY=( $(compgen -W "rebuild" -- ${cur}) )
            #;;
        -t)
            COMPREPLY=( $(compgen -W "${BUILD_PARTS}" -- ${cur}) )
            ;;
        *)
            COMPREPLY=( $(compgen -W "${ARGS}" -- ${cur}) )
            ;;
    esac
    return 0
}
complete -F _build mk



BASE_PROJECTS=`ls ${CODE_ROOT}/device/mikimobile/`
function _clone_project()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    case $prev in
        \./clone_project\.sh|clone_project\.sh)
            COMPREPLY=( $(compgen -W "clean ${BASE_PROJECTS}" -- ${cur}) )
            ;;
        clean)
            COMPREPLY=( $(compgen -W "${BASE_PROJECTS}" -- ${cur}) )
            ;;
    esac

    return 0
}
complete -o dirnames -F _clone_project clone_project.sh

