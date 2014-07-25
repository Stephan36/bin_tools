#!/bin/bash
#
# Convert diff output to colorized HTML.

OIFS=$IFS
IFS=''
echo '<pre>'
echo '<body style="background-color:#000000;">'
read -r s

endofshortmessage=0
while [ $? -eq 0 ]
do
    # Get beginning of line to determine what type
    # of diff line it is.
    t1=${s:0:1}
    t2=${s:0:2}
    t3=${s:0:3}
    t4=${s:0:4}
    t5=${s:0:5}
    t6=${s:0:6}
    t8=${s:0:8}

    # Convert &, <, > to HTML entities.
    s=$(sed -e 's/\&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' <<<"$s")

    # Determine HTML class to use.
    if [ "$t8" == "deleted " -o "$t8" == "new file" ]; then
        echo '<span style="color:#ffffff;">'${s}'</span>'
    elif [ "$t6" == "commit" ]; then
        echo '<span style="color:#bbbb00;">'${s}'</span>'
    elif [ "$t5" == "index" ]; then
        echo '<span style="color:#ffffff;">'${s}'</span>'
    elif [ "$t4" == "diff" ]; then
        echo '<span style="color:#ffffff;">'${s}'</span>'
    elif  [ "$t3" == "+++"  ]; then
        echo '<span style="color:#ffffff;">'${s}'</span>'
    elif  [ "$t3" == "---"  ]; then
        echo '<span style="color:#ffffff;">'${s}'</span>'
    elif  [ "$t2" == "@@"   ]; then
        LEFT="`echo "${s}" | sed "s/ @@ .*/ @@/"`"
        RIGHT="`echo "${s}" | sed "s/.* @@//"`"
        echo '<span style="color:#00bbbb;">'${LEFT}'</span><span style="color:#bbbbbb;">'${RIGHT}'</span>'
    elif  [ "$t1" == "+"    ]; then
        echo '<span style="color:#00bb00;">'${s}'</span>'
    elif  [ "$t1" == "-"    ]; then
        echo '<span style="color:#bb0000;">'${s}'</span>'
    elif  [ "${s#*Short message: in project}" != "${s}" ]; then
        PRO=${s#*Short message: in project}
        MSG=${s%$PRO}
        echo '<span style="color:#bbbbbb;">'${MSG}'<span><span style="color:#bb0000;">'${PRO}'<span>'
    elif [ "${s#*Full message:}" != "${s}" ]; then
        endofshortmessage=1
        echo '<span style="color:#bbbbbb;">'${s}'</span>'
    else
        if [ "${endofshortmessage}" == "0" ]; then
            echo '<span style="color:#00bb00;">'${s}'</span>'
        else
            echo '<span style="color:#bbbbbb;">'${s}'</span>'
        fi
    fi

    read -r s
done
IFS=$OIFS
echo '</pre>'
