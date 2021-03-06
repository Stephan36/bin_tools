#!/system/bin/sh
#!/bin/bash

#PAKS="com.android.contacts com.android.mms com.android.dialer com.android.stk com.mediatek.FMRadio"
PAKS=""
WHAT_PAKS=""

if [ "$#" != "0" ]; then
    PAKS=$@
fi

for pak in ${PAKS}; do
   WHAT_PAKS+=" -p ${pak} "
done

LOG_DIR="/sdcard/monkey"
mkdir -p $LOG_DIR
index=0
while [ 1 ]; do
    screenrecord ${LOG_DIR}/movie_${index}.mp4
    let index+=1
    let rm_index=index-4
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
monkey -s 1  ${WHAT_PAKS} -v -v -v --throttle 300 99999999 --ignore-crashes --ignore-timeouts > ${LOG_DIR}/monkey.log 2&> ${LOG_DIR}/error.log
set +x
sleep 3
busybox killall -SIGINT screenrecord
echo "monkey test done"
echo 1 > /data/stop_record

