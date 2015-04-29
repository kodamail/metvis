#!/bin/sh
#
# only for git-version data_conv
#
# ./make.sh input-job-dir [output-img-dir [test]]
#
. ./common.sh
. ./usr/common.sh
#
echo "$0 $@ ($(date))"
echo
#
#========== arguments ==========
#
DIR_INPUT_JOB=$1
DIR_OUTPUT_IMG=$2  # draw first figure unless specified.
RUN_MODE=$3        # "test" if debug mode
#
if [ ! -d "${DIR_INPUT_JOB}" ] ; then
    echo "usage: $0 input-job-dir [output-img-dir [test]]"
    echo
    exit 1
fi
if [ ! -f ${DIR_INPUT_JOB}/configure ] ; then
    echo "error in $0: ${DIR_INPUT_JOB}/configure does not exist."
    exit 1
fi
. ./${DIR_INPUT_JOB}/configure
#
if [ "${DIR_OUTPUT_IMG}" = "" ] ; then
    echo "$0: display test mode"
    RUN_MODE="test"
elif [ ! -d "${DIR_OUTPUT_IMG}" ] ; then
    echo "creating ${DIR_OUTPUT_IMG}"
    mkdir -p ${DIR_OUTPUT_IMG} || exit 1
fi
#
#========== loop for all the figures ==========
#
i=1
if [ -f ${DIR_INPUT_JOB}/resume.txt -a "${RESUME}" = "yes" ] ; then
    i=$( cat ${DIR_INPUT_JOB}/resume.txt )
fi
while [ 1 -eq 1 ] ; do
    echo $i > ./${DIR_INPUT_JOB}/resume.txt  # for resume
    rm -rf temp_$$
    mkdir temp_$$
    #
    #----- parse job list -----
    #
    ./parse_list.pl file=./${DIR_INPUT_JOB}/${JOB_LIST} count=$i \
	ftype=${TARGET_FTYPE} \
	mode=${TARGET_MODE} \
	run1=${TARGET_RUN1} \
	run2=${TARGET_RUN2} \
	varid=${TARGET_VARID} \
	> temp_$$/temp.dat || exit 1
    #
    [ ! -s temp_$$/temp.dat ] && break
    DESC=( $( sed temp_$$/temp.dat -e "1,1p" -e d ) )
    DIR=( $( sed temp_$$/temp.dat -e "2,2p" -e d ) )
    echo -n "$i: ${DIR[@]}"
    #
    #----- initial check -----
    #
    if [ ${#DESC[@]} -ne ${#DIR[@]} ] ; then
	let i=i+1
	echo " -> skip: inconsistent number of parameters (${#DESC[@]} vs. ${#DIR[@]})"
	continue
    fi
    #
    HEAD=img
    EPS=${HEAD}.eps  # internal image format
    PNG=${HEAD}.png  # standard image format
    GIF=${HEAD}.gif  # format for aninmation
    TXT=${HEAD}.txt  # description
    #
    FTYPE=""
    MODE=""
    VARID=""
    TIMEID=""
    REGION=""
    #
    YEAR=""
    SEASON=""
    MONTH=""
    DAY=""
    HOUR="00"
    #
    YEARS=""
    #YEAR_START=""
    #YEAR_END=""
    #
    YEAR2=""
    MONTH2=""
    DAY2=""
    HOUR2="00"
    #
    DIFF_Y=""
    #
    LON_MIN=""
    LON_MID=""
    LON_MAX=""
    #
    ANIM_DLON=""
    #
    MATRIX_TYPE=""
    #
    OUTPUT_DIR=${DIR_OUTPUT_IMG}
    echo
    for(( j=0; ${j}<${#DESC[@]}; j=${j}+1 )) ; do
#	echo "${DESC[$j]} ${DIR[$j]}"
	OUTPUT_DIR=${OUTPUT_DIR}/$( echo ${DIR[$j]} | sed -e "s/^-/m/g" )
	[ "${DESC[$j]}" = "ftype"       ] && FTYPE=${DIR[$j]}
	[ "${DESC[$j]}" = "mode"        ] && MODE=${DIR[$j]}
	[ "${DESC[$j]}" = "varid"       ] && VARID=${DIR[$j]}
	[ "${DESC[$j]}" = "region"      ] && REGION=${DIR[$j]}
	[ "${DESC[$j]}" = "timeid"      ] && TIMEID=${DIR[$j]}
	[ "${DESC[$j]}" = "year"        ] && YEAR=${DIR[$j]}
	[ "${DESC[$j]}" = "years"       ] && YEARS=${DIR[$j]}
	#[ "${DESC[$j]}" = "year_start" ] && YEAR_START=${DIR[$j]}
	#[ "${DESC[$j]}" = "year_end"   ] && YEAR_END=${DIR[$j]}
	[ "${DESC[$j]}" = "season"      ] && SEASON=${DIR[$j]}
	[ "${DESC[$j]}" = "month"       ] && MONTH=${DIR[$j]}
	[ "${DESC[$j]}" = "day"         ] && DAY=${DIR[$j]}
	[ "${DESC[$j]}" = "hour"        ] && HOUR=${DIR[$j]}
	[ "${DESC[$j]}" = "year2"       ] && YEAR2=${DIR[$j]}
	[ "${DESC[$j]}" = "month2"      ] && MONTH2=${DIR[$j]}
	[ "${DESC[$j]}" = "day2"        ] && DAY2=${DIR[$j]}
	[ "${DESC[$j]}" = "hour2"       ] && HOUR2=${DIR[$j]}
	[ "${DESC[$j]}" = "diff_y"      ] && DIFF_Y=${DIR[$j]}
	[ "${DESC[$j]}" = "lon_min"     ] && LON_MIN=${DIR[$j]}
	[ "${DESC[$j]}" = "lon_mid"     ] && LON_MID=${DIR[$j]}
	[ "${DESC[$j]}" = "lon_max"     ] && LON_MAX=${DIR[$j]}
	[ "${DESC[$j]}" = "anim_dlon"   ] && ANIM_DLON=${DIR[$j]}
	[ "${DESC[$j]}" = "matrix_type" ] && MATRIX_TYPE=${DIR[$j]}
	[ "${DESC[$j]}" = "sw"          ] && SW=${DIR[$j]}  # don't use it if possible
	[ "${DESC[$j]}" = "sw2"         ] && SW2=${DIR[$j]} # don't use it if possible

#LIST=( $( get_list_name list/run_list.txt ) )
#	COMMENT1=$( ./get_list_by_name.pl file=list/${DESC[$j]}_list.txt name="${DIR[$j]}" num=1 )
#	COMMENT2=$( ./get_list_by_name.pl file=list/${DESC[$j]}_list.txt name="${DIR[$j]}" num=2 )
#	echo "${DESC[$j]}=${DIR[$j]}: ${COMMENT1}" >> ${TXT}
#	if [ "${COMMENT2}" != "" ] ; then
#	    echo "  ${COMMENT2}" >> ${TXT}
#	fi
#	echo "" >> ${TXT}

    done

    if [ "${OVERWRITE}" != "yes" \
	-a -f ${OUTPUT_DIR}/${PNG} ] ; then
	let i=i+1
	echo " -> already exists"
	continue
    fi
    if [ "${OVERWRITE}" != "yes" \
	-a -f ${OUTPUT_DIR}/${GIF} ] ; then
	let i=i+1
	echo " -> already exists"
	continue
    fi
    #
    #----- check consistency & set necessary values -----
    #
    [ "${FTYPE}" = "" ] && echo "FTYPE is void" && exit 1
    #
    [ "${MODE}" = "" ] && echo "MODE is void" && exit 1
    #
    [ "${VARID}" = "" -a "${FTYPE}" != "isccp_matrix" ] && echo "VARID is void" && exit 1
    #
    case "${TIMEID}" in
	"annual_mean" )
	    [ "${YEAR}"   = "" ] && echo "error: YEAR is void" && exit 1
	    ;;
	"seasonal_mean" )
	    [ "${YEAR}"   = "" ] && echo "error: YEAR is void" && exit 1
	    [ "${SEASON}" = "" ] && echo "error: SEASON is void" && exit 1
	    [ "${SEASON}" = "MAM" ] && MONTH="345"
	    [ "${SEASON}" = "JJA" ] && MONTH="678"
	    [ "${SEASON}" = "SON" ] && MONTH="901"
	    [ "${SEASON}" = "DJF" ] && MONTH="212"
	    ;;
	"monthly_mean" )
	    [ "${YEAR}"   = "" ] && echo "error: YEAR is void" && exit 1
	    [ "${MONTH}"  = "" ] && echo "error: MONTH is void" && exit 1
	    ;;
	"clim_annual_mean" )
	    [ "${YEARS}"  = "" ] && echo "error: YEARS is void" && exit 1
	    ;;
	"clim_seasonal_mean" )
	    [ "${YEARS}"  = "" ] && echo "error: YEARS is void" && exit 1
	    [ "${SEASON}" = "" ] && echo "error: SEASON is void" && exit 1
	    [ "${SEASON}" = "MAM" ] && MONTH="345"
	    [ "${SEASON}" = "JJA" ] && MONTH="678"
	    [ "${SEASON}" = "SON" ] && MONTH="901"
	    [ "${SEASON}" = "DJF" ] && MONTH="212"
	    ;;
	"clim_monthly_mean" )
	    [ "${YEARS}"  = "" ] && echo "error: YEARS is void" && exit 1
	    [ "${MONTH}"  = "" ] && echo "error: MONTH is void" && exit 1
	    ;;
    esac



    : <<'#COMMENT_EOF'
    elif [ "${TIMEID}" = "1dy_mean" \
	-o "${TIMEID}" = "5dy_mean" ] ; then
	[ "${TIMEID}" = "tstep"    ] && DELTA_DAY=1
	[ "${TIMEID}" = "1dy_mean" ] && DELTA_DAY=1
	[ "${TIMEID}" = "5dy_mean" ] && DELTA_DAY=5
	[ "${YEAR}"   = "" ] && echo "YEAR is void" && exit 1
	[ "${MONTH}"  = "" ] && echo "MONTH is void" && exit 1
	[ "${DAY}"    = "" ] && echo "DAY is void" && exit 1
	if [ "${MODE}" = "model_raw_anim" ] ; then
	    [ "${YEAR2}"   = "" ] && echo "YEAR2 is void"  && exit 1
	    [ "${MONTH2}"  = "" ] && echo "MONTH2 is void" && exit 1
	    [ "${DAY2}"    = "" ] && echo "DAY2 is void"   && exit 1
	fi
	STR_MONTH=jun
	YMD=$(   date --date "${YEAR}-${MONTH}-${DAY}" +%d%b%Y )
	YMDPP=$( date --date "${YEAR}-${MONTH}-${DAY} +${DELTA_DAY}days" +%d%b%Y )
	YMD2=$(  date --date "${YEAR2}-${MONTH2}-${DAY2}" +%d%b%Y )
#	echo ${YMDPP}
	STR_TIME="-time ${YMD} ${YMDPP}"

    elif [ "${TIMEID}" = "tstep" \
	-o "${TIMEID}" = "1hr_mean" ] ; then
	[ "${YEAR}"   = "" ] && echo "YEAR is void"  && exit 1
	[ "${MONTH}"  = "" ] && echo "MONTH is void" && exit 1
	[ "${DAY}"    = "" ] && echo "DAY is void"   && exit 1
	[ "${HOUR}"   = "" ] && echo "HOUR is void"  && exit 1
	export LANG=en
	STR_MONTH=jun
	YMDH=$(  date --date "${YEAR}-${MONTH}-${DAY} ${HOUR}:00" +%Hz%d%b%Y )
	if [ "${MODE}" = "model_raw_anim" ] ; then
	    [ "${YEAR2}"   = "" ] && echo "YEAR2 is void"  && exit 1
	    [ "${MONTH2}"  = "" ] && echo "MONTH2 is void" && exit 1
	    [ "${DAY2}"    = "" ] && echo "DAY2 is void"   && exit 1
	    [ "${HOUR2}"   = "" ] && echo "HOUR2 is void"  && exit 1
	    YMDH2=$( date --date "${YEAR2}-${MONTH2}-${DAY2} ${HOUR2}:00" +%Hz%d%b%Y )
	fi

    else
	echo ""
	echo "TIMEID = ${TIMEID} is NOT supported" && exit 1
    fi
#COMMENT_EOF

    [ "${RUN_MODE}" != "test" -a ! -d ${OUTPUT_DIR} ] && mkdir -p ${OUTPUT_DIR}

    OUTPUT_DIR=${DIR_OUTPUT_IMG}
    for(( j=0; ${j}<${#DESC[@]}; j=${j}+1 )) ; do
	[ "${RUN_MODE}" != "test" ] && echo ${DESC[$j]} > ${OUTPUT_DIR}/.type
	OUTPUT_DIR=${OUTPUT_DIR}/$( echo ${DIR[$j]} | sed -e "s/^-/m/g" )
    done

    echo ""
    for(( j=1; $j<=15; j=$j+1 )) ; do
	let jp2=j+2
	LINE_LIST[$j]=$( cat temp_$$/temp.dat | sed -e "${jp2},${jp2}p" -e d )
	VARID_LIST[$j]=$( echo "${LINE_LIST[$j]}" | awk '{ print $2 }' )
    done
    rm temp_$$/temp.dat


    FLAG_GRADS=0

    #
    #----- create cnf for ${FTYPE}.gs -----
    #
    # common for all
    cat > temp_$$/cnf_${FTYPE}.gsf <<EOF
function cnf_${FTYPE}()
    _varid = '${VARID}'
EOF
    #
    # display style
    case "${MODE}" in
	"model_bias" | "sens_model" )
	    cat >> temp_$$/cnf_${FTYPE}.gsf <<EOF
    _disp.1 = '1'
    _disp.2 = '2'
    _disp.5 = '2 1'
    _cbar.2 = 'hor'
    _cbar.5 = 'hor'
EOF
	    if [ "${FTYPE}" = "latlev" ] ; then
		cat >> temp_$$/cnf_${FTYPE}.gsf <<EOF
    _cont.1 = 'on'
    _cont.2 = 'on'
    _over.5 = '1'
EOF
	    fi
	    ;;
	"sens_model_bias" )
	    cat >> temp_$$/cnf_${FTYPE}.gsf <<EOF
    _disp.1 = '1'
    _disp.2 = '2'
    _disp.3 = '3'
    _disp.4 = '3 2'
    _disp.5 = '2 1'
    _disp.6 = '3 1'
    _cbar.3 = 'hor'
    _cbar.6 = 'hor'
EOF
	    if [ "${FTYPE}" = "latlev" ] ; then
		cat >> temp_$$/cnf_${FTYPE}.gsf <<EOF
    _cont.1 = 'on'
    _cont.2 = 'on'
    _cont.3 = 'on'
    _cont.4 = 'off'
    _over.4 = '2'
    _over.5 = '1'
    _over.6 = '1'
EOF
	    fi
	    ;;
	* )
	    echo "error: MODE=${MODE} is invalid."
	    exit 1
	    ;;
    esac
    #
    # time
    case "${TIMEID}" in
	"annual_mean" )
	    cat >> temp_$$/cnf_${FTYPE}.gsf <<EOF
    _year  = ${YEAR}
    _month = 999
EOF
#    _month = 999${MONTH}
	    ;;
	"seasonal_mean" | "monthly_mean" )
	    cat >> temp_$$/cnf_${FTYPE}.gsf <<EOF
    _year  = ${YEAR}
    _month = ${MONTH}
EOF
	    ;;
	"clim_annual_mean" )
	    cat >> temp_$$/cnf_${FTYPE}.gsf <<EOF
    _year       = 'clim'
    _year_start = ${YEARS:0:4}
    _year_end   = ${YEARS:5:4}
    _month      = 999
EOF
	    ;;
	"clim_seasonal_mean" | "clim_monthly_mean" )
	    cat >> temp_$$/cnf_${FTYPE}.gsf <<EOF
    _year       = 'clim'
    _year_start = ${YEARS:0:4}
    _year_end   = ${YEARS:5:4}
    _month      = ${MONTH}
EOF
	    ;;
	* )
	    echo "error: TIMEID=${TIMEID} is invalid."
	    exit 1
	    ;;
    esac
    #
    # for each dataset
    cat >> temp_$$/cnf_${FTYPE}.gsf <<EOF
    f = 1
EOF
    IFS_ORG=${IFS}
    IFS=$'\n'
    for LINE in ${LINE_LIST[@]} ; do
	echo ${LINE}
	cat >> temp_$$/cnf_${FTYPE}.gsf <<EOF
    ret = run_list( '${LINE}' )
    _run.f = subwrd( ret, 2 )
    _var.f = subwrd( ret, 4 )
    if( _var.f != '' ) ; _f2df.f = last() ; f = f + 1 ; endif
EOF
    done
    IFS=${IFS_ORG}
    #
    # file name for saving img
    if [ "${DIR_OUTPUT_IMG}" != "" ] ; then
	cat >> temp_$$/cnf_${FTYPE}.gsf <<EOF
    _save = '${HEAD}'
EOF
    fi
    #
    # common for all
    cat >> temp_$$/cnf_${FTYPE}.gsf <<EOF
    _fmax = f - 1
    _region = '${REGION}'
return
EOF


    : <<'#COMMENT_EOF'

    ###########################################
    #  latlon_type1
    ###########################################
    if [ "${FTYPE}" = "latlon_type1" ] ; then

	##### model_bias, gw #####
	if [ "${MODE}" = "model_bias" -o "${MODE}" = "gw" -o "${MODE}" = "clim_change" ] ; then
	    cat > ${FTYPE}.dat <<EOF
${VARID}
${STR_TIME}
2
${LINE_LIST[1]}
${LINE_LIST[2]}
1
2


2 1

${HEAD}
EOF
	##### model_raw #####
	elif [ "${MODE}" = "model_raw" ] ; then
	    cat > ${FTYPE}.dat <<EOF
${VARID}
${STR_TIME}
1
${LINE_LIST[2]}

1




${HEAD}
EOF

	##### model_sens #####
	elif [ "${MODE}" = "model_sens" ] ; then # general form
	    cat > ${FTYPE}.dat <<EOF
${VARID}
${STR_TIME}
${LINE_LIST[1]}
EOF
	    for(( j=1; $j<=${LINE_LIST[1]}+6; j=$j+1 )) ; do
	        echo "${LINE_LIST[$j+1]}" >> ${FTYPE}.dat
	    done
	    
	    echo "${HEAD}" >> ${FTYPE}.dat

	    #cat ${FTYPE}.dat

	else
	    echo "error: MODE=${MODE} is not supported"
	    exit 1
	fi

    ###########################################
    #  latlev_type1
    ###########################################
    elif [ "${FTYPE}" = "latlev_type1" ] ; then

	##### model_bias, gw #####
	if [ "${MODE}" = "model_bias" -o "${MODE}" = "gw" -o "${MODE}" = "clim_change" ] ; then
	    cat > ${FTYPE}.dat <<EOF
${VARID}
${STR_TIME}
2
${LINE_LIST[1]}
${LINE_LIST[2]}
1
2


2 1

${HEAD}
EOF
	##### model_raw #####
	elif [ "${MODE}" = "model_raw" ] ; then
	    cat > ${FTYPE}.dat <<EOF
${VARID}
${STR_TIME}
1
${LINE_LIST[2]}

1




${HEAD}
EOF

	##### model_sens #####
	elif [ "${MODE}" = "model_sens" ] ; then # general form
	    cat > ${FTYPE}.dat <<EOF
${VARID}
${STR_TIME}
${LINE_LIST[1]}
EOF
	    for(( j=1; $j<=${LINE_LIST[1]}+6; j=$j+1 )) ; do
	        echo "${LINE_LIST[$j+1]}" >> ${FTYPE}.dat
	    done
	    
	    echo "${HEAD}" >> ${FTYPE}.dat

	    #cat ${FTYPE}.dat

	else
	    echo "error: MODE=${MODE} is not supported"
	    exit 1
	fi

    ###########################################
    #  latlon_isccp
    ###########################################
    elif [ "${FTYPE}" = "latlon_isccp" ] ; then

	if [ "${MODE}" = "model_bias_diff" ] ; then
	    cat > ${FTYPE}.dat <<EOF
diff
${VARID}
${STR_TIME}
2
${LINE_LIST[1]}
${LINE_LIST[2]}
${LINE_LIST[3]}
${LINE_LIST[4]}
${HEAD}
EOF
	elif [ "${MODE}" = "model_bias_raw" ] ; then
	    cat > ${FTYPE}.dat <<EOF
raw
${VARID}
${STR_TIME}
2
${LINE_LIST[1]}
${LINE_LIST[2]}
${LINE_LIST[3]}
${LINE_LIST[4]}
${HEAD}
EOF
	elif [ "${MODE}" = "model_raw" ] ; then
	    cat > ${FTYPE}.dat <<EOF
raw
${VARID}
${STR_TIME}
1
${LINE_LIST[1]}
${LINE_LIST[2]}
${HEAD}
EOF
	else
	    echo "error: MODE=${MODE} is not supported"
	    exit 1
	fi

    ###########################################
    #  latlon_isccp2
    ###########################################
    elif [ "${FTYPE}" = "latlon_isccp2" ] ; then

	if [ "${MODE}" = "model_bias_diff" -o "${MODE}" = "model_gw_diff" ] ; then
	    cat > ${FTYPE}.dat <<EOF
${VARID} ${VARID_LIST[@]}
${STR_TIME}
6
${LINE_LIST[1]}
${LINE_LIST[2]}
${LINE_LIST[3]}
${LINE_LIST[4]}
${LINE_LIST[5]}
${LINE_LIST[6]}
1
2
3
4 1
5 2
6 3
${HEAD}
EOF
	elif [ "${MODE}" = "model_bias_raw" -o "${MODE}" = "model_gw_raw" ] ; then
	    cat > ${FTYPE}.dat <<EOF
${VARID} ${VARID_LIST[@]}
${STR_TIME}
6
${LINE_LIST[1]}
${LINE_LIST[2]}
${LINE_LIST[3]}
${LINE_LIST[4]}
${LINE_LIST[5]}
${LINE_LIST[6]}
1
2
3
4
5
6
${HEAD}
EOF
	elif [ "${MODE}" = "model_raw" ] ; then
	    cat > ${FTYPE}.dat <<EOF
isccp_high_vis isccp_high_vis isccp_middle_vis isccp_low_vis
${STR_TIME}
3
${LINE_LIST[1]}
${LINE_LIST[2]}
${LINE_LIST[3]}
1
2
3



${HEAD}
EOF
	else
	    echo "error: MODE=${MODE} is not supported"
	    exit 1
	fi

    ###########################################
    #  sphere
    ###########################################
    elif [ "${FTYPE}" = "sphere" ] ; then

	##### model_raw_anim #####
	if [ "${MODE}" = "model_raw_anim" -o "${MODE}" = "model_raw"  ] ; then

	    v=1
	    for(( v=1; $v<=2; v=$v+1 )) ; do
		cat > temp.gs <<EOF
'reinit'
rc = gsfallow("on")

ret = run_list( '${LINE_LIST[$v]}' )
'q file'
line = sublin( result, 2 )
ctl = subwrd( line, 2 )
ret = write( 'temp.txt', ctl )
'quit'
EOF
		grads -blc "temp.gs"
		CTL[$v]=$( cat temp.txt )
		rm temp.gs temp.txt
	    done

	    echo ${DIR}

	    if [ "${MODE}" = "model_raw_anim" ] ; then
		./anim.sh ${YMDH} ${YMDH2} ${LON_MID} ${ANIM_DLON} ${VARID} ${CTL[1]} ${CTL[2]}
		mv anim.gif ${OUTPUT_DIR}/img.gif
		i=$( expr $i + 1 )
		continue
	    elif [ "${MODE}" = "model_raw"  ] ; then
		./anim.sh ${YMDH} ${YMDH} ${LON_MID} 0 ${VARID} ${CTL[1]} ${CTL[2]} "noanim"
		mv png/anim_*.png ${PNG} || exit 1
		touch ${TXT}
		FLAG_GRADS=1
	    fi

	    
	fi


    elif [ "${FTYPE}" = "isccp_matrix" ] ; then

	##### isccp_matrix, bias, gw #####
	if [ "${MODE}" = "model_bias" -o "${MODE}" = "gw" -o "${MODE}" = "clim_change" ] ; then
	    cat > ${FTYPE}.dat <<EOF
${MATRIX_TYPE}
${STR_TIME}
2
${LINE_LIST[1]}
${LINE_LIST[2]}
${LINE_LIST[3]}
${LINE_LIST[4]}
${LINE_LIST[5]}
${LINE_LIST[6]}
2 1
${HEAD}
EOF
	elif [ "${MODE}" = "model_raw" ] ; then
	    cat > ${FTYPE}.dat <<EOF
${MATRIX_TYPE}
${STR_TIME}
1
${LINE_LIST[1]}
${LINE_LIST[2]}
${LINE_LIST[3]}
1
${HEAD}
EOF
        fi

    else
	echo "error: FTYPE=${FTYPE} is not supported"
	exit 1
    fi
#COMMENT_EOF

#    if [ "${OVERWRITE}" = "yes" ] ; then
    if [ ${FLAG_GRADS} -eq 0 ] ; then
	cd temp_$$
	#
#	echo "Followings are cnf_${FTYPE}.gsf for ${FTYPE}.gs" >> ${TXT}
#	echo "-----" >> ${TXT}
#	cat cnf_${FTYPE}.gsf >> ${TXT}
#	echo "-----" >> ${TXT}
	#
	for FILE in ${FILE_LIST_TEMPLATE[@]} ; do
	    ln -s ${DIR_TEMPLATE}/${FILE}
	done
	#
	if [ "${RUN_MODE}" = "test" ] ; then
	    cat cnf_${FTYPE}.gsf
	    grads -lc "${FTYPE}.gs cnf_${FTYPE}.gsf" | tee grads.log 2>&1
	    cd ..
	    rm -r temp_$$
	    exit
	else
	    grads -blcx "${FTYPE}.gs cnf_${FTYPE}.gsf" | tee grads.log 2>&1
	fi
	#
	ERROR=$( grep -i "error" grads.log )
	ERROR=${ERROR}$( grep -i "all undefined values" grads.log )
	ERROR=${ERROR}$( grep -i "Data Request Warning" grads.log )
	if [ "${ERROR}" != "" ] ; then
	    echo
	    echo "error occurred!"
	    echo "see temp_$$/grads.log for details"
	    echo
	    exit 1
	fi
#	rm grads.log cnf_${FTYPE}.gsf
	for FILE in ${FILE_LIST_TEMPLATE[@]} ; do
	    rm ${FILE}
	done
        #
	[ -f ${EPS} ] && eps2png ${EPS}
	cd ..
    fi
    #
#    mv temp_$$/${PNG} temp_$$/${TXT} ${OUTPUT_DIR}
    mv temp_$$/${PNG} temp_$$/grads.log temp_$$/cnf_${FTYPE}.gsf ${OUTPUT_DIR}
    rm -f temp_$$/${EPS}
    ls temp_$$
    rmdir temp_$$
    #
    ##############################
    let i=i+1
done

echo
echo "$0 normally finished ($(date))"
echo
exit
