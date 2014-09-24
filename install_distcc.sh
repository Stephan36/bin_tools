#!/bin/bash

_LOCAL_PATH=`pwd`
LOCAL_PATH=`echo $_LOCAL_PATH | sed 's/\//\\\\\\//g'`

echo "Install distcc"
sudo apt-get install distcc

# setup distcc
sudo sed -i 's/^STARTDISTCC=.*/STARTDISTCC="true"/g' /etc/default/distcc
sudo sed -i 's/^ALLOWEDNETS=.*/ALLOWEDNETS="127.0.0.1 172.18.0.0\/16"/g' /etc/default/distcc
ip_addr=`ifconfig eth0 | sed -n '2 p' | awk -F' ' '{print $2}' | awk -F: '{print $2}'`
sudo sed -i 's/^LISTENER=.*/LISTENER="'$ip_addr'"/g' /etc/default/distcc


# unpackge compile tools
echo "Unpackge compile tools"
tar zxf distcc_android.tar.gz

# setup compile tools PATH
already_set=`grep "PATH=.*distcc_android.*" /etc/init.d/distcc`
if [ "$already_set" = "" ]; then
    sudo sed -i 's/^PATH=/PATH='$LOCAL_PATH'\/distcc_android\/arm-linux-tools\/tools\/gcc-sdk:'$LOCAL_PATH'\/distcc_android\/arm-linux-tools\/gcc\/linux-x86\/arm\/arm-linux-androideabi-4.7\/bin:'$LOCAL_PATH'\/distcc_android\/x86-linux-tools\/x86_64-linux-android-4.7\/bin:/g' /etc/init.d/distcc
fi

# setup compile tools soft link to distcc
host_path="$_LOCAL_PATH/distcc_android/arm-linux-tools/tools/gcc-sdk"
host_cc=`ls $host_path`

arm_target_path="$_LOCAL_PATH/distcc_android/arm-linux-tools/gcc/linux-x86/arm/arm-linux-androideabi-4.7/bin"
arm_target_cc=`ls $arm_target_path`

x86_target_path="$_LOCAL_PATH/distcc_android/x86-linux-tools/x86_64-linux-android-4.7/bin"
x86_target_cc=`ls $x86_target_path`


echo "setup compile tools soft link to distc"
echo "Enter /usr/lib/distcc"
cd /usr/lib/distcc
all_cc="$host_cc $arm_target_cc $x86_target_cc"
for cc in $all_cc; do
    if [ -f "$cc" ]; then
        sudo rm  $cc
    fi
    sudo ln -s ../../bin/distcc $cc
done
cd -

use_exist=`grep "^export USE_DISTCC" ~/.bashrc`
if [ "$use_exist" == "" ]; then
    echo "export USE_DISTCC=true" >> ~/.bashrc
else
    sed -i 's/^export USE_DISTCC.*/export USE_DISTCC=true/g' ~/.bashrc
fi
# restart distcc
sudo /etc/init.d/distcc restart
