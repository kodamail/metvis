export PATH=/hoge/bash_common/release-20151012:${PATH}
. bash_common.sh

DIR_GTEMPLATE=/hoge/gtemplate/release-20151013
FILE_LIST_GTEMPLATE=( \
    isccp_matrix.gs  \
    latlev.gs        \
    latlon.gs        \
    latzm.gs         \
    set_region.gsf   \
    set_time.gsf     \
    spm.gs
    )

OVERWRITE="no"
#OVERWRITE="yes"   # BE CAREFUL !!!
