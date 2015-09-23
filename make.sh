#!/bin/sh
#
# only for git-version data_conv
#
# ./make.sh input-job-dir [output-img-dir [test]]
#
# new
# ./make.sh [--test] [output-img-dir] job-1 [job-2 ...]
#
. ./common.sh     || exit 1
. ./usr/common.sh || exit 1
#
#echo "$0 $@ ($(date))"
echo "$0 ($(date))"
echo
#
#========== arguments ==========
#
#DIR_INPUT_JOB=$1
#DIR_OUTPUT_IMG=$2  # draw first figure unless specified.
#RUN_MODE=$3        # "test" if debug mode
#
RUN_MODE=""
DIR_OUTPUT_IMG=""
FILE_JOB_LIST=()
while [ "$1" != "" ] ; do
    if [ "$1" = "--test" ] ; then
	RUN_MODE="test"
    elif [ "${DIR_OUTPUT_IMG}" = "" -a -d "$1" ] ; then
	DIR_OUTPUT_IMG=$1
    elif [ -f "$1" ] ; then
	FILE_JOB_LIST=( ${FILE_JOB_LIST[@]} $1 )
    else
	echo "error in $0: argument $1 is not supported (or directory does not exist)."
	exit 1
    fi
    shift
done

echo "FILE_JOB_LIST: ${FILE_JOB_LIST[@]}"
echo "DIR_OUTPUT_IMG: ${DIR_OUTPUT_IMG}"
echo "RUN_MODE: ${RUN_MODE}"
#exit

#
#if [ ! -d "${DIR_INPUT_JOB}" ] ; then
if [ ${#FILE_JOB_LIST[@]} -eq 0 ] ; then
#    echo "usage: $0 input-job-dir [output-img-dir [test]]"
    echo "usage:"
    echo "  $0 [--test] [output-img-dir] job-1 [job-2 ...]"
    echo
    exit 1
fi
#if [ ! -f ${DIR_INPUT_JOB}/configure ] ; then
#    echo "error in $0: ${DIR_INPUT_JOB}/configure does not exist."
#    exit 1
#fi
#. ./${DIR_INPUT_JOB}/configure
#
if [ "${DIR_OUTPUT_IMG}" = "" ] ; then
    echo "$0: display test mode"
    RUN_MODE="test"
#elif [ ! -d "${DIR_OUTPUT_IMG}" ] ; then
#    echo "creating ${DIR_OUTPUT_IMG}"
#    mkdir -p ${DIR_OUTPUT_IMG} || exit 1
fi
#
#========== loop for all the figures ==========
#
for FILE_JOB in ${FILE_JOB_LIST[@]} ; do
    i=1
    if [ "${RESUME}" = "yes" ] ; then
	RESUME=${FILE_JOB}_resume.txt
	if [ -f "${RESUME}" ] ; then
	    i=$( cat ${RESUME} )
	fi
	echo $i > ./${RESUME}
    fi

    while [ 1 -eq 1 ] ; do  # i-loop
	rm -rf temp_$$
	mkdir temp_$$
        #
        #----- parse job list -----
        #
	./parse_list.pl file=${FILE_JOB} count=$i \
	    > temp_$$/temp.dat || exit 1
#	./parse_list.pl file=./${DIR_INPUT_JOB}/${JOB_LIST} count=$i \
#	    ftype=${TARGET_FTYPE} \
#	    mode=${TARGET_MODE} \
#	    run1=${TARGET_RUN1} \
#	    run2=${TARGET_RUN2} \
#	    varid=${TARGET_VARID} \
#	    > temp_$$/temp.dat || exit 1
cat temp_$$/temp.dat
exit 1
        #
	[ ! -s temp_$$/temp.dat ] && break
	DESC=( $( sed temp_$$/temp.dat -e "1,1p" -e d ) )
	DIR=( $( sed temp_$$/temp.dat -e "2,2p" -e d ) )
	echo -n "$i: ${DIR[@]}"
        #
        #----- initial check -----
        #
	if [ "${#DESC[@]}" -ne "${#DIR[@]}" ] ; then
	    echo " -> skip: inconsistent number of parameters (${#DESC[@]} vs. ${#DIR[@]})"
	    let i=i+1
	    continue
	fi
        #
	HEAD=img
	EPS=${HEAD}.eps  # internal image format
	PNG=${HEAD}.png  # standard image format
	GIF=${HEAD}.gif  # format for aninmation
	TXT=${HEAD}.txt  # description
        #
#	FTYPE=""
#	MODE=""
#	VARID=""
#	TIMEID=""
#	REGION=""
#        #
#	YEAR=""
#	SEASON=""
#	MONTH=""
#	DAY=""
	HOUR="00"
#        #
#	YEARS=""
#        #
#	YEAR2=""
#	MONTH2=""
#	DAY2=""
	HOUR2="00"
#        #
#	DIFF_Y=""
#        #
#	LON_MIN=""
#	LON_MID=""
#	LON_MAX=""
#        #
#	ANIM_DLON=""
#        #
#	MATRIX_TYPE=""
#        #
	OUTPUT_DIR=${DIR_OUTPUT_IMG}
	echo
	for(( j=0; ${j}<${#DESC[@]}; j=${j}+1 )) ; do
#	echo "${DESC[$j]} ${DIR[$j]}"
	    OUTPUT_DIR=${OUTPUT_DIR}/$( echo ${DIR[$j]} | sed -e "s/^-/m/g" )

	    # set DESC_*, e.g., DESC_mode="model_bias"
	    NAME=$( echo ${DESC[$j]} | sed -e "s/-/_/g" )
	    eval DESC_${NAME}=${DIR[$j]}
	    # TODO: replace below with above (DESC_*)

	    [ "${DESC[$j]}" = "ftype"       ] && FTYPE=${DIR[$j]}
	    [ "${DESC[$j]}" = "mode"        ] && MODE=${DIR[$j]}
	    [ "${DESC[$j]}" = "varid"       ] && VARID=${DIR[$j]}
	    [ "${DESC[$j]}" = "region"      ] && REGION=${DIR[$j]}
	    [ "${DESC[$j]}" = "timeid"      ] && TIMEID=${DIR[$j]}
	    [ "${DESC[$j]}" = "year"        ] && YEAR=${DIR[$j]}
	    [ "${DESC[$j]}" = "years"       ] && YEARS=${DIR[$j]}
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
	done

	if [ "${OVERWRITE}" != "yes" \
	    -a -f ${OUTPUT_DIR}/${PNG} ] ; then
	    echo " -> already exists"
	    let i=i+1
	    continue
	fi
	if [ "${OVERWRITE}" != "yes" \
	    -a -f ${OUTPUT_DIR}/${GIF} ] ; then
	    echo " -> already exists"
	    let i=i+1
	    continue
	fi
        #
        #----- check consistency & set necessary values -----
        #
	[ "${FTYPE}" = "" ] && { echo "FTYPE is void" ; exit 1 ; }
        #
	[ "${MODE}" = "" ] && { echo "MODE is void" ; exit 1 ; }
        #
	[ "${VARID}" = "" -a "${FTYPE}" != "isccp_matrix" ] && { echo "VARID is void" ; exit 1 ; }
        #
	[ "${FTYPE}" = "isccp_matrix" -a "${MATRIX_TYPE}" = "" ] && { echo "MATRIX_TYPE is void" ; exit 1 ; }
        #
	case "${TIMEID}" in
	    "annual_mean" )
		[ "${YEAR}"   = "" ] && { echo "error: YEAR is void" ; exit 1 ; }
		;;
	    "seasonal_mean" )
		[ "${YEAR}"   = "" ] && { echo "error: YEAR is void"   ; exit 1 ; }
		[ "${SEASON}" = "" ] && { echo "error: SEASON is void" ; exit 1 ; }
		[ "${SEASON}" = "MAM" ] && MONTH="345"
		[ "${SEASON}" = "JJA" ] && MONTH="678"
		[ "${SEASON}" = "SON" ] && MONTH="901"
		[ "${SEASON}" = "DJF" ] && MONTH="212"
		;;
	    "monthly_mean" )
		[ "${YEAR}"   = "" ] && { echo "error: YEAR is void"  ; exit 1 ; }
		[ "${MONTH}"  = "" ] && { echo "error: MONTH is void" ; exit 1 ; }
		;;
	    "clim_annual_mean" )
		[ "${YEARS}"  = "" ] && { echo "error: YEARS is void" ; exit 1 ; }
		;;
	    "clim_seasonal_mean" )
		[ "${YEARS}"  = "" ] && { echo "error: YEARS is void"  ; exit 1 ; }
		[ "${SEASON}" = "" ] && { echo "error: SEASON is void" ; exit 1 ; }
		[ "${SEASON}" = "MAM" ] && MONTH="345"
		[ "${SEASON}" = "JJA" ] && MONTH="678"
		[ "${SEASON}" = "SON" ] && MONTH="901"
		[ "${SEASON}" = "DJF" ] && MONTH="212"
		;;
	    "clim_monthly_mean" )
		[ "${YEARS}"  = "" ] && { echo "error: YEARS is void" ; exit 1 ; }
		[ "${MONTH}"  = "" ] && { echo "error: MONTH is void" ; exit 1 ; }
		;;
	esac

	[ "${RUN_MODE}" != "test" -a ! -d "${OUTPUT_DIR}" ] && mkdir -p ${OUTPUT_DIR}

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
    rc = gsfpath( '/cwork5/kodama/gscript/run_list' )
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
	if [ "${FTYPE}" = "isccp_matrix" ] ; then
	    cat >> temp_$$/cnf_${FTYPE}.gsf <<EOF
    _type = '${MATRIX_TYPE}'
EOF
	fi
	#
        # for each dataset
	cat >> temp_$$/cnf_${FTYPE}.gsf <<EOF
    f = 1
EOF
	IFS_ORG=${IFS}
	IFS=$'\n'
	for LINE in ${LINE_LIST[@]} ; do
	    echo ${LINE}

	    if [ "${FTYPE}" = "isccp_matrix" ] ; then
		cat >> temp_$$/cnf_${FTYPE}.gsf <<EOF
    dir = run_list( '${LINE} -show-dir' )
    _run.f = subwrd( '${LINE}', 1 )
    if( _run.f = 'ISCCP_D1_OBS' )
      _type.f = 'satellite'
      prex( 'open 'dir'/isccp_d1.ctl' )
      _var.f = ''
      _f2df.f = last()
      _var_pres.f = ''
      f = f + 1
    else
      _type.f = 'nicam'
      prex( 'open 'dir'/isccp/144x72x49/monthly_mean/dfq_isccp2/dfq_isccp2.ctl' )
      _var.f = 'dfq_isccp2.'f
      _f2df.f = last()
      'open 'dir'/ml_zlev/144x72x38/monthly_mean/ms_pres/ms_pres.ctl'
      _var_pres.f = 'ms_pres.'_f2df.f+1
      f = f + 1
    endif
EOF
	    else
		cat >> temp_$$/cnf_${FTYPE}.gsf <<EOF
    ret = run_list( '${LINE}' )
    _run.f = subwrd( ret, 2 )
    _var.f = subwrd( ret, 4 )
    if( _var.f != '' ) ; _f2df.f = last() ; f = f + 1 ; endif
EOF
	    fi
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
	    for FILE in ${FILE_LIST_TEMPLATE[@]} ; do
		rm ${FILE}
	    done
            #
	    [ -f ${EPS} ] && eps2png ${EPS}
	    cd ..
	fi
        #
	mv temp_$$/${PNG} temp_$$/grads.log temp_$$/cnf_${FTYPE}.gsf ${OUTPUT_DIR}
	rm -f temp_$$/${EPS}
	ls temp_$$
	rmdir temp_$$
        #
        ##############################
	let i=i+1
    done
done

echo
echo "$0 normally finished ($(date))"
echo
exit
