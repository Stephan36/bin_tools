#!/bin/bash
PROJECTS=${LUNCH_MENU_CHOICES[*]/*aosp*/}
PROJECTS=`echo ${PROJECTS} | sed 's/\S*\(dax1\|emulator\|full_fugu\|m_e_arm\)\S*//g'`
BUILD_PARTS="kernel lk preloader boot otapackage systemimage bootimage snod"
