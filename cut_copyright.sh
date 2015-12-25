#!/bin/bash

unmatch="AAAAAAAAAA"
for tf in `find -name "*.php"`; do
    line=`grep -n  '\s\*\sECSHOP' $tf  | awk -F: '{print $1}'`

    t_line=$line
    start_line=0
    while true; do
        if [[ $t_line == 0 ]]; then
            break;
        fi
        #content="$t_line"`sed -n "${t_line}p" $tf | grep -o "[^ ]\+\( \+[^ ]\+\)*"`
        #content=`sed -n "${t_line}p" $tf`
        content=`sed -n ''${t_line}'s/^\s*\*\+.*/'$unmatch'/p' $tf`
        #echo $content
        if [[ $content =~ $unmatch ]]; then
            #sed -i ''${t_line}'d' $tf
            #echo "match"
            temp=$t_line
        else
            #echo "yy$content"
            start_line=$t_line
            break;
        fi
        let t_line=$t_line-1
    done
    #echo $line
    #echo "start: $start_line";
    t_line=$line
    n_line=`wc -l $tf | awk '{print $1}'`
    end_line=$start_line;
    while true; do
        if [[ $t_line == $n_line ]]; then
            break;
        fi
        content=`sed -n ''${t_line}'s/^\s*\*\+.*/'$unmatch'/p' $tf`
        #echo $content
        if [[ $content =~ $unmatch ]]; then
            #sed -i ''${t_line}'d' $tf
            #echo "match"
            temp=$t_line
        else
            #echo "yy$content"
            let end_line=$t_line-1
            break;
        fi
        let t_line=$t_line+1
    done
    #echo "end: $end_line"
    if [[ $start_line == 0 || $end_line == 0 ]];then
        continue;
    fi
    sed -i ${start_line},${end_line}d $tf
done
