#!/bin/bash

PROJECTS=$(perl mediatek/build/tools/listP.pl)
NATIVE_ACTIONS=" customimage bootimage systemimage recoveryimage secroimage cacheimage factoryimage
    userdataimage userdataimage-nodeps target-files-package
    sdk win_sdk banyan_addon banyan_addon_x86 cts otapackage dist updatepackage
    update-api snod dump-comp-build-info"
ACTIONS="new n bm_new remake r bm_remake clean c listproject listp mm
            drvgen codegen emigen nandgen custgen javaoptgen ptgen run-preprocess remove-preprocessed
            check-modem update-modem sign-image encrypt-image sign-modem check-dep
            dump-memusage gen-relkey check-appres
            rel-cust modem-info bindergen mrproper"
MODULES="preloader lk kernel android drvgen codegen emigen nandgen custgen javaoptgen ptgen"
OPTIONS="-o=TARGET_BUILD_VARIANT=eng -t"
S_IMAGES="boot.img cache.img EBR1 EBR2 lk.bin logo.bin MBR recovery.img secro.img sro-lock.img sro-unlock.img system.img userdata.img"
# ./mk [$OPTION] [$PROJECT] $ACTION|$NATIVE_ACTION [$MODULE]
function _mk()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    case $prev in
        \./mk|\./makeMtk|mk|makeMtk)
            COMPREPLY=( $(compgen -W "${PROJECTS} ${OPTIONS} ${ACTIONS}" -- ${cur}) )
            ;;
        n|r|new|remake)
            COMPREPLY=( $(compgen -W "${MODULES} ${NATIVE_ACTIONS}" -- ${cur}) )
            ;;
        user|eng|userdebug|-t|no)
# mk -o=TARGET_BUILD_VARIANT=user|eng -t $project $action
            COMPREPLY=( $(compgen -W "${PROJECTS} ${OPTIONS}" -- ${cur}) )
            ;;
        sign-image)
            COMPREPLY=( $(compgen -W "${S_IMAGES}" -- ${cur}) )
            ;;
        *)
            COMPREPLY=( $(compgen -W "${ACTIONS} ${NATIVE_ACTIONS} ${OPTIONS}" -- ${cur}) )
            ;;
    esac

    return 0
}
complete -o dirnames -F _mk mk
complete -o dirnames -F _mk makeMtk


function _clone_project()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    case $prev in
        \./clone_project\.sh|clone_project\.sh)
            COMPREPLY=( $(compgen -W "clean ${PROJECTS}" -- ${cur}) )
            ;;
        clean)
            COMPREPLY=( $(compgen -W "${PROJECTS}" -- ${cur}) )
            ;;
    esac

    return 0
}
complete -o dirnames -F _clone_project clone_project.sh


per_models="ir receiver nfc motor hall alsps gy modem camera msensor"
sub_cams="gc0328_yuv gc2236_raw"
main_cams="gc2235_raw gc2235_mipi_raw ov5648_mipi_raw"
main_afs="fm50af"
function _custom_peripherals()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    prev_prev="${COMP_WORDS[COMP_CWORD-2]}"
    model="${COMP_WORDS[2]}"

    # model
    if [ "$COMP_CWORD" == "2" ]; then
        COMPREPLY=( $(compgen -W "${per_models}" -- ${cur}) )
        return 0
    fi
    if [ "$model" == "camera" ]; then
        case $COMP_CWORD in
            3)
                COMPREPLY=( $(compgen -W "$sub_cams" -- ${cur}) )
                ;;
            4)
                COMPREPLY=( $(compgen -W "$main_cams" -- ${cur}) )
                ;;
            5)
                COMPREPLY=( $(compgen -W "$main_afs" -- ${cur}) )
                ;;
        esac
        return 0
    fi
    case $prev in
        \./custom_peripherals\.sh|custom_peripherals\.sh)
            COMPREPLY=( $(compgen -W "${PROJECTS}" -- ${cur}) )
            ;;
        ir|receiver|nfc|motor|hall)
            COMPREPLY=( $(compgen -W "on off" -- ${cur}) )
            ;;
        alsps|gy|camera) 
            COMPREPLY=( $(compgen -W "78 10" -- ${cur}) )
            ;;
        msensor)
            COMPREPLY=( $(compgen -W "akm09911 off" -- ${cur}) )
            ;;
        modem)
            COMPREPLY=( $(compgen -W "`ls -1 mediatek/custom/common/modem/`" -- ${cur}) )
            ;;
        78|10) 
            case $prev_prev in
                alsps)
                    COMPREPLY=( $(compgen -W "als alsps off" -- ${cur}) )
                    ;;
                gy)
                    COMPREPLY=( $(compgen -W "g gy" -- ${cur}) )
                    ;;
            esac
            ;;
    esac

    return 0
}
complete -F _custom_peripherals custom_peripherals.sh 
complete -F _custom_peripherals ./custom_peripherals.sh 
