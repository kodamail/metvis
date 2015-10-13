#!/bin/sh
. ./usr/common.sh || exit 1
export LANG=en

RUNID=$1
TYPE=$2  # e.g., "ys"

#exit  # If you don't use astarisk in job/, exit this script here.

# TODO; ya06 (annual mean starting from June)

grads -xblc "${DIR_GTEMPLATE}/get_ymd.gs ${RUNID} temp.$$" > /dev/null
YMD_LIST=( $( cat temp.$$ | sed -e "s/-/ /g" ) ) # TODO: in future. more than one YMD range will be supported.
rm temp.$$

[ ${#YMD_LIST[@]} -eq 1 ] && exit

if [ ${YMD_LIST[0]} -gt ${YMD_LIST[1]} ] ; then
    RET=""
elif [ "${TYPE}" = "ymd" ] ; then
    continue

elif [ "${TYPE}" = "ym" ] ; then
    YM1=$( date --date "${YMD_LIST[0]} 1 second ago" +%Y%m )
    YM1=$( date --date "${YM1}01 1 month" +%Y%m )
    YM2=$( date --date "${YMD_LIST[1]} 1 day" +%Y%m )
    YM2=$( date --date "${YM2}01 1 month ago" +%Y%m )
    RET="${YM1:0:4},${YM1:4:2},${YM2:0:4},${YM2:4:2}"

elif [ "${TYPE}" = "ys" ] ; then
    YM1=$( date --date "${YMD_LIST[0]} 1 second ago" +%Y%m )
    YM1=$( date --date "${YM1}01 1 month" +%Y%m )
    YEAR1=${YM1:0:4}
    MONTH1=${YM1:4:2} ; MONTH1=${MONTH1#0}
    if   [ ${MONTH1} -le 3 ] ; then 
	MONTH1=3
	RET="${YEAR1},MAM"
    elif [ ${MONTH1} -le 6 ] ; then
	MONTH1=6
	RET="${YEAR1},JJA"
    elif [ ${MONTH1} -le 9 ] ; then
	MONTH1=9
	RET="${YEAR1},SON"
    else
	MONTH1=12
	RET="${YEAR1},DJF"
    fi
    YM2=$( date --date "${YMD_LIST[1]} 1 day" +%Y%m )
    YM2=$( date --date "${YM2}01 1 month ago" +%Y%m )
    YEAR2=${YM2:0:4}
    MONTH2=${YM2:4:2} ; MONTH2=${MONTH2#0}
    if   [ ${MONTH2} -le 1 ] ; then 
	let YEAR2=YEAR2-1
	MONTH=9
	RET="${RET},${YEAR2},SON"
    elif [ ${MONTH2} -le 4 ] ; then
	let YEAR2=YEAR2-1
	MONTH=12
	RET="${RET},${YEAR2},DJF"
    elif [ ${MONTH2} -le 7 ] ; then
	MONTH=3
	RET="${RET},${YEAR2},MAM"
    elif [ ${MONTH2} -le 10 ] ; then
	MONTH=6
	RET="${RET},${YEAR2},JJA"
    else
	MONTH=9
	RET="${RET},${YEAR2},SON"
    fi
    [ ${YEAR1} -gt ${YEAR2} ] && RET=""
    [ ${YEAR1} -eq ${YEAR2} -a ${MONTH1} -gt ${MONTH2} ] && RET=""

elif [ "${TYPE}" = "ya" ] ; then
    Y1=$( date --date "${YMD_LIST[0]} 1 second ago" +%Y )
    Y1=$( date --date "${Y1}0101 1 year" +%Y )
    Y2=$( date --date "${YMD_LIST[1]} 1 day" +%Y )
    Y2=$( date --date "${Y2}0101 1 year ago" +%Y )
    [ ${Y1} -le ${Y2} ] && RET="${Y1},${Y2}"

elif [ "${TYPE}" = "cym" ] ; then
    YM1=$( date --date "${YMD_LIST[0]} 1 second ago" +%Y%m )
    YM1=$( date --date "${YM1}01 1 month" +%Y%m )
    YM2=$( date --date "${YMD_LIST[1]} 1 day" +%Y%m )
    YM2=$( date --date "${YM2}01 1 month ago" +%Y%m )
    if [ ${YM1:4:2} -le ${YM2:4:2} ] ; then
	RET="${YM1:0:4}-${YM2:0:4},${YM1:4:2},${YM2:4:2}"
	if [ "${YM1:4:2}" != "01" -a ${YM1:0:4} -lt ${YM2:0:4} ] ; then
	    let Y=${YM1:0:4}+1
	    M=${YM1:4:2} ; let M=${M#0}-1 ; M=$( printf "%02d" ${M} )
	    RET="${RET} ${Y}-${YM2:0:4},01,${M}"
	fi
	if [ "${YM2:4:2}" != "12" -a ${YM1:0:4} -lt ${YM2:0:4} ] ; then
	    let Y=${YM2:0:4}-1
	    M=${YM2:4:2} ; let M=${M#0}+1 ; M=$( printf "%02d" ${M} )
	    RET="${RET} ${YM1:0:4}-${Y},${M},12"
	fi
    else
	let Y=${YM1:0:4}+1
	RET="${Y}-${YM2:0:4},01,${YM2:4:2}"
	let Y1=${YM1:0:4}+1
	let Y2=${YM2:0:4}-1
	M1=${YM1:4:2} ; let M1=${M1#0}-1 ; M1=$( printf "%02d" ${M1} )
	M2=${YM2:4:2} ; let M2=${M2#0}+1 ; M2=$( printf "%02d" ${M2} )
	[ ${M2} -le ${M1} ] && RET="${RET} ${Y1}-${Y2},${M2},${M1}"
	let Y=${YM2:0:4}-1
	RET="${RET} ${YM1:0:4}-${Y},${YM1:4:2},12"
    fi

elif [ "${TYPE}" = "cys" ] ; then
    YM1=$( date --date "${YMD_LIST[0]} 1 second ago" +%Y%m )
    YM1=$( date --date "${YM1}01 1 month" +%Y%m )
    while [ "${YM1:4:2}" != "03" -a "${YM1:4:2}" != "06" -a "${YM1:4:2}" != "09" -a "${YM1:4:2}" != "12" ] ; do
	YM1=$( date --date "${YM1}01 1 month" +%Y%m )
    done
    YM2=$( date --date "${YMD_LIST[1]} 1 day" +%Y%m )
    YM2=$( date --date "${YM2}01 1 month ago" +%Y%m )
    while [ "${YM2:4:2}" != "02" -a "${YM2:4:2}" != "05" -a "${YM2:4:2}" != "08" -a "${YM2:4:2}" != "11" ] ; do
	YM2=$( date --date "${YM2}01 1 month ago" +%Y%m )
    done
    #
    # MAM
    Y1=${YM1:0:4}
    [ ${YM1:4:2} != "03" ] && let Y1=Y1+1
    Y2=${YM2:0:4}
    [ ${YM2:4:2} = "02" ] && let Y2=Y2-1
    RET="${Y1}-${Y2},MAM,MAM"
    #
    # JJA
    Y1=${YM1:0:4}
    [ ${YM1:4:2} != "03" -a ${YM1:4:2} != "06" ] && let Y1=Y1+1
    Y2=${YM2:0:4}
    [ ${YM2:4:2} = "02" -o  ${YM2:4:2} = "05" ] && let Y2=Y2-1
    RET="${RET} ${Y1}-${Y2},JJA,JJA"
    #
    # SON
    Y1=${YM1:0:4}
    [ ${YM1:4:2} != "03" -a ${YM1:4:2} != "06" -a ${YM1:4:2} != "09" ] && let Y1=Y1+1
    Y2=${YM2:0:4}
    [ ${YM2:4:2} = "02" -o  ${YM2:4:2} = "05" -o  ${YM2:4:2} = "08" ] && let Y2=Y2-1
    RET="${RET} ${Y1}-${Y2},SON,SON"
    #
    # DJF
    Y1=${YM1:0:4}
    Y2=${YM2:0:4}
    let Y2=Y2-1
    RET="${RET} ${Y1}-${Y2},DJF,DJF"

elif [ "${TYPE}" = "cya" ] ; then
    Y1=$( date --date "${YMD_LIST[0]} 1 second ago" +%Y )
    Y1=$( date --date "${Y1}0101 1 year" +%Y )
    Y2=$( date --date "${YMD_LIST[1]} 1 day" +%Y )
    Y2=$( date --date "${Y2}0101 1 year ago" +%Y )
    [ ${Y1} -le ${Y2} ] && RET="${Y1}-${Y2}"

fi

echo ${RET}
