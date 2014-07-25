#!/bin/bash
SDK_INFO=sdk_info.txt
if [ $# -lt 1 ]; then
    echo "Usage: $0 dir"
    exit 1
else
    if [ ! -d $1 ]; then
        echo "Usage: $0 dir ."
        exit 1
    fi
fi
MAIL_CONTENT=/tmp/mail.txt
REPO_INFO=/tmp/repo.txt
CMD_STOP_FILE=/run/lock/repo-mail-stop
REPO_PID_DIR=/run/lock/repo-mail

TARGET_DIR=`readlink -f $1`
# send_one_commit $commi $sdk_info $project
function send_one_commit() {
    AUTHOR=`git log --pretty=format:"%an" -1 $1`
    EMAIL_ADDR=`git log --pretty=format:"%ae" -1 $1`
    SDK_NAME=`sed -n '1p' $2/$SDK_INFO`
    RECEIVER=`sed -n '2p' $2/$SDK_INFO`
    #RECEIVER=`echo $RECEIVER | sed "s/$EMAIL_ADDR//"`
    rm $MAIL_CONTENT.git
    echo "From: Mid-Marvell<Mid.Marvell@cvte.cn>" > $MAIL_CONTENT
    echo "Content-type: text/html;charset=UTF-8" >> $MAIL_CONTENT
    echo "To: $RECEIVER" >> $MAIL_CONTENT
    echo "Subject: ($AUTHOR) commit code in [$SDK_NAME]" >> $MAIL_CONTENT
    FILE_COUNT=`git log --pretty=format:"%B" -1 $1 | wc -l`
    echo ">>>> Short message: in project $3" >> $MAIL_CONTENT.git
    echo "-------------------------------------" >> $MAIL_CONTENT.git
    git show --stat --pretty=format:"%an<%ae>%n%n%B%n" -1 $1 >> $MAIL_CONTENT.git
    echo "" >> $MAIL_CONTENT.git
    echo "" >> $MAIL_CONTENT.git
    echo ">>>> Full message:" >> $MAIL_CONTENT.git
    git show -1 $1 >> $MAIL_CONTENT.git
    cat $MAIL_CONTENT.git | /usr/bin/diff2html.sh  >> $MAIL_CONTENT
    sendmail -t < $MAIL_CONTENT
}

MK_WK_FLAG_FILE="/tmp/wk_list.flag"
MAIL_WK_LIST="/tmp/wk_mail.tmp"
function send_wk_list() {
    _PWD=`pwd`
    cd $1
    SDK_NAME=`sed -n '1p' $1/$SDK_INFO`
    PMM_LIST=`sed -n '2p' $1/$SDK_INFO`
    DAY=`date +%-d`
    #debug_wk_list=true
    if [ "$debug_wk_list" == "true" ]; then
        DAY=25
        PMM_LIST="xiongjianfei@cvte.cn"
    fi

    if [ "$DAY" == "25" ]; then
        HOUR=`date +%-H`
        if [ "$HOUR" == "11" ]; then
            if [ ! -e $MK_WK_FLAG_FILE ]; then
                touch $MK_WK_FLAG_FILE
            fi
        fi
        if [ "$debug_wk_list" == "true" ]; then
            HOUR=12
        fi

        if [ "$HOUR" == "12" ]; then
            if [ -e $MK_WK_FLAG_FILE ]; then
                pwd
                ./mkwklist.sh
                WK_LIST_FILE=`ls *.csv`
                echo "From: MidGitLog<MidGitLog@cvte.cn>" > $MAIL_WK_LIST
                echo "Content-type: text/html;charset=UTF-8" >> $MAIL_WK_LIST
                echo "To: $PMM_LIST" >> $MAIL_WK_LIST
                echo "Subject: $SDK_NAME $WK_LIST_FILE" >> $MAIL_WK_LIST
                echo "<pre>" >> $MAIL_WK_LIST
                echo "<table border=1 cellSpacing=0 cellPadding=5>" >> $MAIL_WK_LIST
                while read LINE
                do
                    echo -n "<tr><td>" >> $MAIL_WK_LIST
                    LINE=`echo -n $LINE | sed  "s;,;</td><td>;g"`
                    while read NAME_TAB
                    do
                        ENG_NAME=`echo "$NAME_TAB" | sed "s/ .*//"`
                        CH_NAME=`echo "$NAME_TAB" | sed "s/.* //"`
                        MATCHED=`echo "$LINE" | grep "^$ENG_NAME</td><td>"`
                        if [ "$MATCHED" == "$LINE" ]; then
                            LINE=`echo $LINE | sed "s/^$ENG_NAME/$CH_NAME/"`
                            break
                        fi
                    done < $TARGET_DIR/name_list.xml
                    echo -n $LINE >> $MAIL_WK_LIST
                    echo "</td></tr>" >> $MAIL_WK_LIST
                done < $WK_LIST_FILE
                echo "</table>" >> $MAIL_WK_LIST
                echo "</pre>" >> $MAIL_WK_LIST
                sendmail -t < $MAIL_WK_LIST
                #rm -f $MAIL_WK_LIST
                rm -f $WK_LIST_FILE
                rm -f $MK_WK_FLAG_FILE
            fi
        fi


    fi
    cd $_PWD
}

function process_one_dir() {
    #cd $TARGET_DIR/$1
    cd $1
    if [ -e $REPO_INFO ]; then
        rm $REPO_INFO
    fi
    repo sync -q > $REPO_INFO 2>&1
    PROJECTS=`awk '/^project/ {if (NF == 2) print $NF}' $REPO_INFO | tr '\n' ' '`
    #echo "projects>> $PROJECTS"
    COMMITS=`awk '/^Updating/ {if (NF == 2) print $NF}' $REPO_INFO | tr '\n' ' '`
    #echo "commits>> $COMMITS"
    COMMITS=($COMMITS)
    L_COUNT=0
    for p in $PROJECTS; do
        # ignore repo project
        if [ "$p" == ".repo/repo" ]; then
            continue;
        fi
        cd $p
        echo "$p --> ${COMMITS[$L_COUNT]}"
        l_coms=`git log --pretty=format:"%h" ${COMMITS[$L_COUNT]}`
        for commit in $l_coms; do
            send_one_commit $commit $1 $p
        done
        let L_COUNT+=1
        cd -
    done
    cd $TARGET_DIR
}

# check whether already runing.
if [ ! -d $REPO_PID_DIR ]; then
    mkdir $REPO_PID_DIR
fi
PIDS=`ls $REPO_PID_DIR`
for pid in $PIDS; do
    ps -p $pid > /dev/null
    ret=$?
    if [ $ret == "1" ]; then
        rm $REPO_PID_DIR/$pid
    else
        echo "$0 is running"
        exit 1
    fi
done
touch $REPO_PID_DIR/$$

if [ -e $CMD_STOP_FILE ]; then
    rm $CMD_STOP_FILE
fi
while(true); do
    DIRS=`ls -d $TARGET_DIR/*/`
    echo -n "*"
    for DIR in $DIRS; do
        if [ -d $DIR ]; then
            process_one_dir $DIR
            send_wk_list $DIR
        fi
    done
    COUNT=0
    while(true); do
        sleep 1
        if [ -e $CMD_STOP_FILE ]; then
            rm -f $CMD_STOP_FILE
            echo "exit repo mail service"
            exit
        fi
        let COUNT+=1
        if [ $COUNT -gt 60 ]; then
        #if [ $COUNT -gt 1 ]; then
            break
        fi
    done
done
