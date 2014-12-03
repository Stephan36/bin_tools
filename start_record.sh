#!/system/bin/sh
#!/bin/bash

#PAKS="com.android.contacts com.android.mms com.android.dialer com.android.stk com.mediatek.FMRadio"
PAKS=""
WHAT_PAKS=""

if [ "$#" != "0" ]; then
    PAKS=$@
fi
TIME=3

for pak in ${PAKS}; do
   WHAT_PAKS+=" -p ${pak} "
done

LOG_DIR="/sdcard/monkey"
mkdir -p $LOG_DIR
index=0
while [ 1 ]; do
    screenrecord  --time-limit $TIME ${LOG_DIR}/movie_${index}.mp4 
    let index+=1
    let rm_index=index-50
    rm /sdcard/monkey/movie_${rm_index}.mp4
    ST=`cat /data/stop_record`
    if [ "${ST}" == "1" ]; then
        echo "screenrecord done"
        rm /data/stop_record
        exit
    fi
done &
echo "start monkey test"


set -x
#monkey -s 1  ${WHAT_PAKS} -v -v -v --throttle 300 99999999 --ignore-crashes --ignore-timeouts > ${LOG_DIR}/monkey.log 2&> ${LOG_DIR}/error.log
while [ 1 ]; do
    sleep 1
    ST=`cat /data/stop_record`
    if [ "${ST}" == "1" ]; then
        break;
    fi
done
set +x
sleep 3
busybox killall -SIGINT screenrecord
echo "monkey test done"
echo 1 > /data/stop_record

