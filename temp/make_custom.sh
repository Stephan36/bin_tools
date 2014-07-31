#!/bin/bash

#project=$1
#config_file=$2
project=datamatic_S4_3G
all_config_file=projectconfig.conf

project_config_file="mediatek/config/$project/ProjectConfig.mk"
custom_config_file="mediatek/config/$project/custom.conf"
# for ProjectConfig.mk

DEBUG="true"
function dbg {
    if [ "$DEBUG" = "true" ]; then
        echo $1
    fi
}

function deal_key_value {
    config=$1
    config_file=$2
    key=`echo $config | sed 's/\(.*\)\s*=.*/\1/'`
    value=`echo $config | sed 's/\(.*\)\s*=\s*\(.*\)\s*/\2/'`
    #exist=`grep $key $config_file`
    line=`grep -n "^$key\s*=" $config_file | cut -d: -f1`
    dbg "$key->$value[$line]"
    if [ "$line" != "" ]; then
        sed -i ''$line' d' $config_file
        max_line=`cat $config_file | wc -l`
        if [[ ${line} -gt ${max_line} ]]; then
            line=$max_line
        fi
        sed -i "${line} i${config}" $config_file
    else
        echo $config >> $config_file
    fi
}
function deal_ProjectConfig {
    deal_key_value "$1" "$project_config_file"
}

function deal_custom_conf {
    deal_key_value "$1" "$custom_config_file"
}

settingsprovider_xml_dir="mediatek/custom/$project/resource_overlay/generic/frameworks/base/packages/SettingsProvider/res/values/"
function deal_SettingsProvider {
    default_xml="$settingsprovider_xml_dir/defaults.xml"
    if [ ! -e ${default_xml} ]; then
        mkdir -p $settingsprovider_xml_dir
cat > $default_xml << EOF
<?xml version="1.0" encoding="utf-8"?>
<resources>
</resources>
EOF
    fi
    key=`echo $config | sed 's/.*name=\"\(.*\)\".*/\1/'`
    value=`echo $config | sed 's/.*>\(.*\)<.*/\1/'`
    line=`grep -n ".*name=\"$key\".*" $default_xml| cut -d: -f1`
    echo "$key->$value..$line"
    if [ "$line" != "" ]; then
        #set -x
        sed -i 's/\(.*name=\"'$key'">\)\(.*\)\(<.*\)/\1'$value'\3/' $default_xml
        #set +x
    else
        line=`grep -n "</resources>" $default_xml| cut -d: -f1`
        sed -i "${line} i\ \ \ \ ${config}" $default_xml
    fi
}

deal_function=""
while read config; do
    # trim string
    config=`echo $config`

    if [[ "${config}" == "#end" ]]; then
        deal_function=""
        continue;
    fi
    if [[ "$deal_function" == "" ]]; then
        # get function
        if [[ "${config}" == "#ProjectConfig.mk" ]]; then
            deal_function="deal_ProjectConfig"
            continue
        fi
        if [[ "${config}" == "#custom.conf" ]]; then
            deal_function="deal_custom_conf"
            continue
        fi
        if [[ ${config} =~ ^#SettingsProvider.* ]]; then
            settingsprovider_xml_dir=`echo $config | cut -d' ' -f2`
            echo "settingsprovider_xml_dir: $settingsprovider_xml_dir"
            deal_function="deal_SettingsProvider"
            continue
        fi
    fi
    if [[ "$deal_function" == "" ]]; then
        continue
    fi

    if [[ $config =~ ^#.* ]] || [[ $config =~ ^\s*$ ]]; then
        continue
    fi
    $deal_function "$config"
done < $all_config_file

