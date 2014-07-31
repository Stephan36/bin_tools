#!/bin/bash

dst_project=$1

projects="ASBIS_PMT5777_3G ASBIS_PMT5887_3G ASBIS_PMT5887_3G_DT_PL cvte_752h cvte_752j cvte_852h cvte_852j cvte_factory htt_8382_712h htt_8382_812h kx_8382_712h kx_1012j cvte_1051j"
patch_files=`cat mtk.patch`
#set -x
for pr in $projects; do
    for file in $patch_files; do
        to_file=`echo $file | sed 's/cvt82_tb_kk/'${pr}'/g'`
        #echo "to_file: $to_file"
        cp -va $file $to_file
    done
done

#set +x
