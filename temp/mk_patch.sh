#!/bin/bash

dst_project=$1

#projects="ASBIS_PMT5777_3G ASBIS_PMT5887_3G ASBIS_PMT5887_3G_DT_PL cvte_752h cvte_752j cvte_852h cvte_852j cvte_factory htt_8382_712h htt_8382_812h kx_8382_712h kx_1012j cvte_1051j"
#projects="ASBIS_PMT5777_3G ASBIS_PMT5887_3G ASBIS_PMT5887_3G_DT_PL cvte_752h cvte_752j cvte_852h cvte_852j cvte_factory htt_8382_712h htt_8382_812h kx_8382_712h kx_1012j cvte_1051j condor_1012h cvte_1012h cvte_1051j cvte_1051j_full datamatic_S4_3G"
projects="ASBIS_PMT5117_3G ASBIS_PMT5777_3G ASBIS_PMT5887_3G ASBIS_PMT5887_3G_DT_PL condor_1012h cvte_1012h cvte_1051j cvte_1051j_full cvte_752h cvte_752j cvte_852h cvte_852j cvte_factory datamatic_S4_3G htt_8382_712h htt_8382_712h_w htt_8382_812h kx_1012j kx_8382_712h cvte_752h"
patch_files=`cat mtk.patch`
#set -x
for pr in $projects; do
    for file in $patch_files; do
        to_file=`echo $file | sed 's/cvte_852h/'${pr}'/g'`
        #echo "to_file: $to_file"
        cp -vfa $file $to_file
    done
done

#set +x
