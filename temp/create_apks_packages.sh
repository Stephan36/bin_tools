#!/bin/bash

apps=`find * -maxdepth 0 -type d | cut -d/ -f2`
echo > apps.mk
for app in $apps; do
b_app=`echo $app | tr a-z A-Z`
libs=`ls $app/lib/`
libs=`echo $libs`
echo "$app: $libs"
cat >> apps.mk << EOF

# for $app
ifeq (\$(strip \$(CVTE_${b_app}_SUPPORT)), yes)
    PRODUCT_PACKAGES += $app $libs
endif
ifeq (\$(strip \$(CVTE_${b_app}_VENDOR_SUPPORT)), yes)
    PRODUCT_PACKAGES += $app $libs
endif
# for $app end

EOF
done
