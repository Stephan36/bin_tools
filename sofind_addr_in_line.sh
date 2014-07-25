#!/bin/bash

CROSS_COMPLIE=""

show_usage()
{
	echo -e "usage:\n addr2line -f \$function -e \$file_prefix -a \$address\n\t\t-g \$CROSS_COMPLIE -d[use default]"
}

check_arg()
{
	if [ -z "$1" ];then
		show_usage
		exit 1
	fi
}

while getopts f:e:a:g:d OPT
do
	case $OPT in
		f) FUNCTION=$OPTARG;;
		e) FILE_NAME=$OPTARG;;
		g) CROSS_COMPLIE=$OPTARG;;
		d) CROSS_COMPLIE="arm-none-linux-gnueabi-";;
		a) ADDR=$OPTARG;;
		?)  show_usage
			exit 1;;
	esac
done



#nm ${1}.o | grep ${2}
check_arg ${FUNCTION}
check_arg ${FILE_NAME}
check_arg ${ADDR}


FILE_NAME=`echo $FILE_NAME | sed 's/\.so//'`
ADDR2=`nm ${FILE_NAME}.so | grep -w ${FUNCTION} | awk '{print "0x"$1}'`
ADDR2="0x`printf %x $(($ADDR2 + $ADDR))`"
MSG=`addr2line -e ${FILE_NAME}.so $ADDR2`
MSG1=`echo $MSG | awk -F: '{print $1}'`
MSG2=`echo $MSG | awk -F: '{print $2}'`
echo -e "\033[36m ${MSG1} \033[35m:    \033[31m${MSG2}\033[0m"



