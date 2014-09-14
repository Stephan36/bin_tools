#!/bin/bash

function help {
echo "Usage: $0 \$project \$model \$config"
exit 1
}
function notice {
    echo -e "\033[031m$1\033[0m"
}
function info {
    echo -e "\033[032m$1\033[0m"
}

function check_info {
    notice "If does not work, check $1"
}

function set_macro {
    local project=$1
    local macro=$2
    local value=$3
    if [ "$value" = "off" ]; then
        value=""
    fi
    exist=`grep "^#\?.*$macro=.*" mediatek/config/$project/ProjectConfig.mk`
    if [ "$exist" != "" ]; then
        sed -i 's/^#\?.*'$macro'=.*/'$macro'='$value'/g'  mediatek/config/$project/ProjectConfig.mk
    else
        echo "$macro=$value" >> mediatek/config/$project/ProjectConfig.mk
    fi
    echo -e "\033[033m$macro=$value\033[0m"
}

function set_test_config {
    local project=$1
    local item=$2
    local value=$3
    if [ "$value" = "off" ]; then
        value="no_"
    else
        value=""
    fi
    sed -i 's/.*'${item}'.*/'${value}${item}';/'  mediatek/config/$project/cvt_mid_factory_test.ini
    echo -e "\033[036mcvt factory test: ${value}${item}\033[0m"
}

function replace_config {
    local file=$1
    local pattern=$2
    local dst=$3
    set -x
    echo $dst
    awk 'BEGIN{exist=0}1{if ($0 ~ /'${pattern}'/) {exist++;print "'${dst}'"} else {print $0}}END{if (exist == 0) {print "'${dst}'"}}' $file > /tmp/$$.tmp && mv /tmp/$$.tmp $file
    set +x
    info "$dst"
}


ARGS_COUNT=$#

if [ ${ARGS_COUNT} -lt 3 ]; then
    echo "Argument is not matched."
    help
fi

projects=`./mk listp`
project=$1

exist_project="0"
for pro in $projects; do
    if [ "$pro" == "$project" ]; then
        exist_project="1"
        break
    fi
done
if [ "$exist_project" == "0" ]; then
    echo "No $1 project, please check it!"
    exit 2;
fi

model=$2

# ir, receiver, nfc, motor, hall, alsps, gy(G-sensor & GYRO-sensor), modem(3G), camera, msensor
if [ "$model" == "ir" ]; then
    # usage: ir on/off
    # set IR model et4003, and support IrRemote apk
    # relative config: CUSTOM_KERNEL_IRREMOTE, CVTE_IRREMOTE_APP_SUPPORT, test_ir
    ir_value="off"
    app_value="off"
    if [ "$3" == "on" ]; then
        ir_value="et4003"
        app_value="yes"
    elif [ "$3" == "off" ]; then
        app_value="no"
    fi
    set_macro $project CUSTOM_KERNEL_IRREMOTE  $ir_value
    set_macro $project CVTE_IRREMOTE_APP_SUPPORT $app_value
    set_test_config $project test_ir $ir_value
    check_info "/dev/irremote in init.project.rc"

elif [ "$model" == "receiver" ]; then
    # receiver on/off
    # enablbe/disable receiver
    # relative config: DISABLE_EARPIECE, test_receiver
    if [ "$3" == "on" ]; then
        exist=`grep "^#\?.*DISABLE_EARPIECE=.*" mediatek/config/$project/ProjectConfig.mk`
        if [ "$exist" != "" ]; then
            sed -i 's/^#\?.*DISABLE_EARPIECE=.*/#DISABLE_EARPIECE=yes/g'  mediatek/config/$project/ProjectConfig.mk
        else
            echo "#DISABLE_EARPIECE=yes" >> mediatek/config/$project/ProjectConfig.mk
        fi
        echo "#DISABLE_EARPIECE=yes"
    elif [ "$3" == "off" ]; then
        echo "DISABLE_EARPIECE=yes"
        sed -i 's/^#\?.*DISABLE_EARPIECE=.*/DISABLE_EARPIECE=yes/g'  mediatek/config/$project/ProjectConfig.mk
    fi
    set_test_config $project test_receiver $3

elif [ "$model" == "motor" ]; then
    # usage: motor on/off
    # enablbe/disable motor/vibrator
    # relative config: CUSTOM_KERNEL_VIBRATOR, test_vibrator, CONFIG_MTK_VIBRATOR
    motor_value="off"
    if [ "$3" == "on" ]; then
        motor_value="vibrator"
        sed -i '/CONFIG_MTK_VIBRATOR/d' mediatek/config/$project/autoconfig/kconfig/project
        info "CONFIG_MTK_VIBRATOR=y, define value"
    else
        cp -p mediatek/config/$project/autoconfig/kconfig/project /tmp/$$.tmp
        awk 'BEGIN{exist=0}1{if ($0 ~ /.*CONFIG_MTK_VIBRATOR.*/) {exist++;print "# CONFIG_MTK_VIBRATOR is not set"} else {print $0}}END{if (exist == 0) {print "# CONFIG_MTK_VIBRATOR is not set"}}' mediatek/config/$project/autoconfig/kconfig/project > /tmp/$$.tmp
        mv /tmp/$$.tmp mediatek/config/$project/autoconfig/kconfig/project
        info "# CONFIG_MTK_VIBRATOR is not set"
    fi

    set_macro $project CUSTOM_KERNEL_VIBRATOR $motor_value
    set_test_config $project test_vibrator $motor_value
    check_info "CONFIG_MTK_VIBRATOR autoconfig/kconfig/project"

elif [ "$model" == "hall" ]; then
    # usage: hall on/off
    # relative config: CUSTOM_KERNEL_HALL, test_hall_switch
    hall_value="$3"
    if [ "$3" == "on" ]; then
        hall_value="common"
    fi
    set_macro $project CUSTOM_KERNEL_HALL $hall_value
    set_test_config $project test_hall_switch $hall_value
elif [ "$model" == "modem" ]; then
    # usage: 3g $config
    # relative config: CUSTOM_MODEM
    exist="0"
    config=$3
    for mo in `ls -1 mediatek/custom/common/modem/`; do
        if [ "$config" == "$mo" ]; then
            exist="1"
            break
        fi
    done
    if [ "$exist" == "0" ]; then
        echo "Unsupport $3, only support:"
        echo "${modem}"
        exit 2
    fi
    set_macro $project CUSTOM_MODEM $3

elif [ "$model" == "nfc" ]; then
    # usage: nfc on/off
    # relative config as below: test_nfc
    configs="MTK_BEAM_PLUS_SUPPORT MTK_NFC_ADDON_SUPPORT MTK_NFC_APP_SUPPORT MTK_NFC_MT6605 MTK_NFC_OMAAC_GEMALTO MTK_NFC_OMAAC_SUPPORT MTK_NFC_SUPPORT"
    if [ "$3" == "on" ]; then
        config="yes"
    elif [ "$3" == "off" ]; then
        config="no"
    fi
    for cfg in $configs; do
        set_macro $project ${cfg} ${config}
    done
    set_test_config $project test_nfc $3

    notice "Please check nfc.cfg, nfcse.cfg and GPIO by yourself"
elif [ "$model" == "alsps" ]; then
    # usage: alsps [78|10] [alsps|ps|off]
    # 78 for [7|8] inch project: cm36283
    # 10 for 10 inch project: cm3217
    # Proximity sensor(ALS) and Light sensor(PS)
    # Notes: [7|8], 10 inch use the default ic.
    # CUSTOM_KERNEL_ALSPS, test_light_sensor, test_proximity
    if [ "$ARGS_COUNT" != "4" ]; then
        echo "Usage: $0 $1 alsps on/off [78|10]"
        exit 1
    fi
    ic="off"
    if [ "$4" != "off" ]; then
        (("$3" == "78")) && ic="cm36283" || ic="cm3217"
    fi

    # ps only
    if [ "$4" == "als" ]; then
        set_macro $project CUSTOM_KERNEL_ALS_ONLY yes
        set_test_config $project test_proximity off
    else
        set_macro $project CUSTOM_KERNEL_ALS_ONLY off
        set_test_config $project test_proximity on
    fi
    set_macro $project CUSTOM_KERNEL_ALSPS $ic
    set_test_config $project test_light_sensor $4
elif [ "$model" == "gy" ]; then
    # usage: gy [78|10] g/gy 
    # g/gy: 'g' for accelerometer only, 'gy' for accelerometer and gyroscpe
    # 78 for [7|8] inch project: G:mma865x, GY: mma865x, mpu3050c
    # 10 for 10 inch project:  G:mma865x, GY: mpu6880g, mpu6880gy
    # Notes: [7|8], 10 inch use the default ic.
    # CUSTOM_KERNEL_ACCELEROMETER, CUSTOM_KERNEL_GYROSCOPE, test_g_sensor, test_gyroscope 
    if [ "$ARGS_COUNT" != "4" ]; then
        echo "Usage($ARGS_COUNT): $0 $1 gy g/gy [78|10]"
        exit 1
    fi
    test_g_sensor="off"
    test_gy_sensor="off"
    if [ "$3" == "78" ]; then
        acc="mma865x"
        gy="mpu3050c"
    else
        acc="mpu6880g"
        gy="mpu6880gy"
    fi
    if [ "$4" == "gy" ]; then
        test_gy_sensor="test"
        test_g_sensor="test"
    elif [ "$4" == "g" ]; then
        test_g_sensor="test"
        acc="mma865x"
        gy=""
    fi
    set_macro $project CUSTOM_KERNEL_ACCELEROMETER $acc
    set_macro $project CUSTOM_KERNEL_GYROSCOPE $gy
    set_test_config $project test_g_sensor  $test_g_sensor
    set_test_config $project test_gyroscope $test_gy_sensor


elif [ "$model" == "camera" ]; then
    # usage: camera F B [af]
    # @F: front camera 
    # @B: back camera
    # @[78|10]. screen size
    # 78 for [7|8] inch project: 
    #   F: gc0328_yuv(0.3M), gc2236_raw(2M)
    #   B: gc2235_raw(2M), ov5648_mipi_raw(5M)
    # 10 for 10 inch project:  
    #   F: gc0328_yuv(0.3M), gc2236_raw(2M)
    #   B: gc2235_mipi_raw(2M), ov5648_mipi_raw(5M)
    # @af: support autofocus or not, only support fm50af now
    # E.g. custom_peripherals project camera gc2236_raw gc2235_raw
    # E.g. custom_peripherals project camera gc2236_raw ov5648_mipi_raw fm50af
    # Notes: [7|8], 10 inch use the default ic. Only 5M support AF now
    #########################
    # Configuration
    ##########################
    # camera configs
    # CUSTOM_HAL_IMGSENSOR
    # CUSTOM_HAL_MAIN_IMGSENSOR
    # CUSTOM_HAL_SUB_IMGSENSOR
    # CUSTOM_KERNEL_IMGSENSOR
    # CUSTOM_KERNEL_MAIN_IMGSENSOR
    # CUSTOM_KERNEL_SUB_IMGSENSOR
    ###########################
    # af configs, open config
    # CUSTOM_HAL_LENS=fm50af dummy_lens
    # CUSTOM_HAL_MAIN_BACKUP_LENS=
    # CUSTOM_HAL_MAIN_LENS=fm50af
    # CUSTOM_HAL_SUB_BACKUP_LENS=
    # CUSTOM_HAL_SUB_LENS=dummy_lens
    # CUSTOM_KERNEL_LENS=fm50af dummy_lens
    # CUSTOM_KERNEL_MAIN_BACKUP_LENS=
    # CUSTOM_KERNEL_MAIN_LENS=fm50af
    # CUSTOM_KERNEL_SUB_BACKUP_LENS=
    # CUSTOM_KERNEL_SUB_LENS=dummy_lens
    # E.g. custom_peripherals project camera [78|10] gc2236_raw ov5648_mipi_raw fm50af
    sub_cams="gc0328_yuv gc2236_raw"
    main_cams="gc2235_raw gc2235_mipi_raw ov5648_mipi_raw"
    main_afs="fm50af"
    if [ $ARGS_COUNT -lt 4 ]; then
        echo "usage: camera F B [af]"
        exit 1
    fi
    main_cam="$5"
    sub_cam="$4"
    main_af="$6"
    if [ $ARGS_COUNT -lt 5 ]; then
        sub_af=""
    else
        sub_af="dummy_lens"
    fi
    echo "Camera: main=$main_cam, sub=$sub_cam"
    echo "LENS: main=$main_af, sub=$sub_af"
    sed -i 's/^#\?.*CUSTOM_HAL_IMGSENSOR=.*/CUSTOM_HAL_IMGSENSOR='$main_cam' '$sub_cam'/g'  mediatek/config/$project/ProjectConfig.mk
    sed -i 's/^#\?.*CUSTOM_HAL_MAIN_IMGSENSOR=.*/CUSTOM_HAL_MAIN_IMGSENSOR='$main_cam'/g'  mediatek/config/$project/ProjectConfig.mk
    sed -i 's/^#\?.*CUSTOM_HAL_SUB_IMGSENSOR=.*/CUSTOM_HAL_SUB_IMGSENSOR='$sub_cam'/g'  mediatek/config/$project/ProjectConfig.mk
    sed -i 's/^#\?.*CUSTOM_KERNEL_IMGSENSOR=.*/CUSTOM_KERNEL_IMGSENSOR='$main_cam' '$sub_cam'/g'  mediatek/config/$project/ProjectConfig.mk
    sed -i 's/^#\?.*CUSTOM_KERNEL_MAIN_IMGSENSOR=.*/CUSTOM_KERNEL_MAIN_IMGSENSOR='$main_cam'/g'  mediatek/config/$project/ProjectConfig.mk
    sed -i 's/^#\?.*CUSTOM_KERNEL_SUB_IMGSENSOR=.*/CUSTOM_KERNEL_SUB_IMGSENSOR='$sub_cam'/g'  mediatek/config/$project/ProjectConfig.mk

    sed -i 's/^#\?.*CUSTOM_HAL_LENS=.*/CUSTOM_HAL_LENS='$main_af' '$sub_af'/g'  mediatek/config/$project/ProjectConfig.mk
    sed -i 's/^#\?.*CUSTOM_HAL_MAIN_LENS=.*/CUSTOM_HAL_MAIN_LENS='$main_af'/g'  mediatek/config/$project/ProjectConfig.mk
    sed -i 's/^#\?.*CUSTOM_HAL_SUB_LENS=.*/CUSTOM_HAL_SUB_LENS='$sub_af'/g'  mediatek/config/$project/ProjectConfig.mk
    sed -i 's/^#\?.*CUSTOM_KERNEL_LENS=.*/CUSTOM_KERNEL_LENS='$main_af' '$sub_af'/g'  mediatek/config/$project/ProjectConfig.mk
    sed -i 's/^#\?.*CUSTOM_KERNEL_MAIN_LENS=.*/CUSTOM_KERNEL_MAIN_LENS='$main_af'/g'  mediatek/config/$project/ProjectConfig.mk
    sed -i 's/^#\?.*CUSTOM_KERNEL_SUB_LENS=.*/CUSTOM_KERNEL_SUB_LENS='$sub_af'/g'  mediatek/config/$project/ProjectConfig.mk

    if [ "$6" == "af" ]; then
        # mediatek/config/$project/android.hardware.camera.xml
        #     <feature name="android.hardware.camera.autofocus" />
        exist=`grep autofocus mediatek/config/${project}/android.hardware.camera.xml`
        if [ "$exist" != "" ]; then
            sed -i 's/\s*<!.*android.hardware.camera.autofocus.*/    \<feature name="android.hardware.camera.autofocus" \/\>/' mediatek/config/${project}/android.hardware.camera.xml

        else
            sed -i '$i \<feature name="android.hardware.camera.autofocus" \/\>' mediatek/config/${project}/android.hardware.camera.xml 
        fi
    else
        #exist=`grep autofocus mediatek/config/${project}/android.hardware.camera.xml`
        #if [ "$exist" != "" ]; then
            sed -i "/android.hardware.camera.autofocus/d"  mediatek/config/${project}/android.hardware.camera.xml
        #fi
    fi

elif [ "$model" == "msensor" ]; then
    # usage: msensor akmd09911
    #        msensor off
    # enablbe/disable  msensor
    # relative config: CUSTOM_HAL_MSENSORLIB, test_m_sensor
    set_test_config $project test_m_sensor $3
    set_macro $project CUSTOM_HAL_MSENSORLIB $3
    set_macro $project CUSTOM_KERNEL_MAGNETOMETER $3
fi
echo "set $* done"


