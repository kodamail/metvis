#!/bin/sh
#
# Synoptis
#   ./make.sh [--test | test] [output-img-dir] job-1 [job-2 ...]
#
# Note
#   only for git-version data_conv
#
. ./usr/common.sh || exit 1
create_temp
trap 'finish' 0
TEMP_DIR=${BASH_COMMON_TEMP_DIR}
#
echo "$0 ($(date))"
#
#========== options ==========
#
RUN_MODE=""
DIR_OUTPUT_IMG=""
FILE_JOB_LIST=()
while [ "$1" != "" ] ; do
    if [ "$1" = "--test" -o "$1" = "test" ] ; then
	RUN_MODE="test"
    elif [ "${DIR_OUTPUT_IMG}" = "" -a -d "$1" ] ; then
	DIR_OUTPUT_IMG=$1
    elif [ -f "$1" ] ; then
	FILE_JOB_LIST=( ${FILE_JOB_LIST[@]} $1 )
    else
 	echo "error in $0: argument \"$1\" is not supported (or directory does not exist)."
	exit 1
    fi
    shift
done

if [ ${#FILE_JOB_LIST[@]} -eq 0 ] ; then
    echo
    echo "usage:"
    echo "  $0 [--test | test] [output-img-dir] job-1 [job-2 ...]"
    echo
    exit 1
fi

if [ "${DIR_OUTPUT_IMG}" = "" ] ; then
    echo "forced to set test mode"
    RUN_MODE="test"
fi

if [ "${RUN_MODE}" = "test" ] ; then
    echo
    echo "  FILE_JOB_LIST: ${FILE_JOB_LIST[@]}"
    echo "  DIR_OUTPUT_IMG: ${DIR_OUTPUT_IMG}"
    echo "  RUN_MODE: ${RUN_MODE}"
    echo
fi

cd ${TEMP_DIR}
#
for FILE in ${FILE_LIST_GTEMPLATE[@]} ; do
    ln -s ${DIR_GTEMPLATE}/${FILE}
done
cd - > /dev/null

#
#========== loop for all the job files ==========
#
for FILE_JOB in ${FILE_JOB_LIST[@]} ; do
    #
    #========== loop for all the lines in a job file ==========
    #
    i=1  # figure number
    p=1  # line number
    ./parse_list.pl file=${FILE_JOB} > ${TEMP_DIR}/temp.txt || exit 1
    pmax=$( cat ${TEMP_DIR}/temp.txt | wc -l ) || exit 1
    for(( p=1; ${p}<=${pmax}; p=${p}+1 )) ; do
    	[ ${p} -eq 1 ] && echo "JOB=${FILE_JOB}"
	TMP_LINE=$( sed ${TEMP_DIR}/temp.txt -e "${p},${p}p" -e d ) || exit 1
	if [ "${TMP_LINE}" != "" ] ; then
	    LINE_LIST[${#LINE_LIST[@]}]=${TMP_LINE}
	    continue
	fi
	#
	DESC=( ${LINE_LIST[0]} )
	DIR=(  ${LINE_LIST[1]} )
	echo -n "$i: ${DIR[@]}"
        #
        #----- initial check -----
        #
	if [ "${#DESC[@]}" -ne "${#DIR[@]}" ] ; then
	    echo " -> skip: inconsistent number of parameters (${#DESC[@]} vs. ${#DIR[@]})"
	    let i=i+1
	    LINE_LIST=()
	    continue
	fi
	echo
        #
	#----- set OUTPUT_DIR and several parameters for GrADS gtemplate
	#
	HEAD=img
	OUTPUT_DIR=${DIR_OUTPUT_IMG}
	for(( j=0; ${j}<${#DESC[@]}; j=${j}+1 )) ; do
	    OUTPUT_DIR=${OUTPUT_DIR}/$( echo ${DIR[$j]} | sed -e "s/^-/m/g" ) || exit 1
	    # set DESC_*, e.g., DESC_mode="model_bias"
	    NAME=$( echo ${DESC[$j]} | sed -e "s/-/_/g" ) || exit 1
	    eval DESC_${NAME}=${DIR[$j]} || exit 1
	done
	#
	# check existence of image file
	#
	if [ -f ${OUTPUT_DIR}/${HEAD}.png -o -f ${OUTPUT_DIR}/${HEAD}.gif ] ; then
	    if [ "${OVERWRITE}" != "yes" ] ; then
		echo " -> already exists"
		let i=i+1
		LINE_LIST=()
		continue
	    fi
	fi
        #
        #----- check consistency & set necessary values -----
        #
	[ "${DESC_ftype}" = "" ] && { echo "DESC_ftype is void" ; exit 1 ; }
        #
	[ "${DESC_mode}" = "" ] && { echo "DESC_mode is void" ; exit 1 ; }
        #
	[ "${DESC_varid}" = "" -a "${DESC_ftype}" != "isccp_matrix" ] && { echo "DESC_varid is void" ; exit 1 ; }
        #
	[ "${DESC_ftype}" = "isccp_matrix" -a "${DESC_matrix_type}" = "" ] && { echo "DESC_matrix_type is void" ; exit 1 ; }
        #
	case "${DESC_timeid}" in
	    "annual_mean" )
		[ "${DESC_year}"   = "" ] && { echo "error: DESC_year is void" ; exit 1 ; }
		;;
	    "seasonal_mean" )
		[ "${DESC_year}"   = "" ] && { echo "error: DESC_year is void"   ; exit 1 ; }
		[ "${DESC_season}" = "" ] && { echo "error: DESC_season is void" ; exit 1 ; }
		[ "${DESC_season}" = "MAM" ] && DESC_month="345"
		[ "${DESC_season}" = "JJA" ] && DESC_month="678"
		[ "${DESC_season}" = "SON" ] && DESC_month="901"
		[ "${DESC_season}" = "DJF" ] && DESC_month="212"
		;;
	    "monthly_mean" )
		[ "${DESC_year}"   = "" ] && { echo "error: DESC_year is void"  ; exit 1 ; }
		[ "${DESC_month}"  = "" ] && { echo "error: DESC_month is void" ; exit 1 ; }
		;;
	    "clim_annual_mean" )
		[ "${DESC_years}"  = "" ] && { echo "error: DESC_years is void" ; exit 1 ; }
		;;
	    "clim_seasonal_mean" )
		[ "${DESC_years}"  = "" ] && { echo "error: DESC_years is void"  ; exit 1 ; }
		[ "${DESC_season}" = "" ] && { echo "error: DESC_season is void" ; exit 1 ; }
		[ "${DESC_season}" = "MAM" ] && DESC_month="345"
		[ "${DESC_season}" = "JJA" ] && DESC_month="678"
		[ "${DESC_season}" = "SON" ] && DESC_month="901"
		[ "${DESC_season}" = "DJF" ] && DESC_month="212"
		;;
	    "clim_monthly_mean" )
		[ "${DESC_years}"  = "" ] && { echo "error: DESC_years is void" ; exit 1 ; }
		[ "${DESC_month}"  = "" ] && { echo "error: DESC_month is void" ; exit 1 ; }
		;;
	esac
	#
	[ "${RUN_MODE}" != "test" -a ! -d "${OUTPUT_DIR}" ] && mkdir -p ${OUTPUT_DIR}
	#
	OUTPUT_DIR=${DIR_OUTPUT_IMG}
	for(( j=0; ${j}<${#DESC[@]}; j=${j}+1 )) ; do
	    [ "${RUN_MODE}" != "test" ] && echo ${DESC[$j]} > ${OUTPUT_DIR}/.type
	    OUTPUT_DIR=${OUTPUT_DIR}/$( echo ${DIR[$j]} | sed -e "s/^-/m/g" )
	done
	#
	LINE_LIST=( "${LINE_LIST[@]:2:99}" )  # shift array by 2
	FLAG_GRADS=0
        #
        #----- create cnf for ${DESC_ftype}.gs -----
        #
        # common for all
	cat > ${TEMP_DIR}/cnf_${DESC_ftype}.gsf <<EOF
function cnf_${DESC_ftype}()
    rc = gsfpath( '${DIR_GTEMPLATE} ${DIR_GTEMPLATE}/database' )
    _varid = '${DESC_varid}'
EOF
        #
        # display style
	case "${DESC_mode}" in
	    "model_bias" | "sens_model" )
		cat >> ${TEMP_DIR}/cnf_${DESC_ftype}.gsf <<EOF
    _disp.1 = '1'
    _disp.2 = '2'
    _disp.5 = '2 1'
    _cbar.2 = 'hor'
    _cbar.5 = 'hor'
    _monit.5 = 'bias'
    _monit.6 = 'bias'
EOF
		if [ "${DESC_ftype}" = "latlev" ] ; then
		    cat >> ${TEMP_DIR}/cnf_${DESC_ftype}.gsf <<EOF
    _cont.1 = 'on'
    _cont.2 = 'on'
    _over.5 = '1'
EOF
		fi
		;;
	    "sens_model_bias" )
		cat >> ${TEMP_DIR}/cnf_${DESC_ftype}.gsf <<EOF
    _disp.1 = '1'
    _disp.2 = '2'
    _disp.3 = '3'
    _disp.4 = '3 2'
    _disp.5 = '2 1'
    _disp.6 = '3 1'
    _cbar.3 = 'hor'
    _cbar.6 = 'hor'
    _monit.5 = 'bias'
    _monit.6 = 'bias'
EOF
		if [ "${DESC_ftype}" = "latlev" ] ; then
		    cat >> ${TEMP_DIR}/cnf_${DESC_ftype}.gsf <<EOF
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
		echo "error: DESC_mode=${DESC_mode} is invalid."
		exit 1
		;;
	esac
        #
        # time
	case "${DESC_timeid}" in
	    "annual_mean" )
		cat >> ${TEMP_DIR}/cnf_${DESC_ftype}.gsf <<EOF
    _year  = ${DESC_year}
    _month = 999
EOF
		;;
	    "seasonal_mean" | "monthly_mean" )
		cat >> ${TEMP_DIR}/cnf_${DESC_ftype}.gsf <<EOF
    _year  = ${DESC_year}
    _month = ${DESC_month}
EOF
		;;
	    "clim_annual_mean" )
		cat >> ${TEMP_DIR}/cnf_${DESC_ftype}.gsf <<EOF
    _year       = 'clim'
    _year_start = ${DESC_years:0:4}
    _year_end   = ${DESC_years:5:4}
    _month      = 999
EOF
		;;
	    "clim_seasonal_mean" | "clim_monthly_mean" )
		cat >> ${TEMP_DIR}/cnf_${DESC_ftype}.gsf <<EOF
    _year       = 'clim'
    _year_start = ${DESC_years:0:4}
    _year_end   = ${DESC_years:5:4}
    _month      = ${DESC_month}
EOF
		;;
	    * )
		echo "error: DESC_timeid=${DESC_timeid} is invalid."
		exit 1
		;;
	esac
        #
	if [ "${DESC_ftype}" = "isccp_matrix" ] ; then
	    cat >> ${TEMP_DIR}/cnf_${DESC_ftype}.gsf <<EOF
    _type = '${DESC_matrix_type}'
EOF
	fi
	#
        # for each dataset
	cat >> ${TEMP_DIR}/cnf_${DESC_ftype}.gsf <<EOF
    f = 1
EOF
	IFS_ORG=${IFS}
	IFS=$'\n'
	for LINE in ${LINE_LIST[@]} ; do
	    echo ${LINE}

	    if [ "${DESC_ftype}" = "isccp_matrix" ] ; then
		cat >> ${TEMP_DIR}/cnf_${DESC_ftype}.gsf <<EOF
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
      prex( 'open 'dir'/ml_zlev/144x72x38/monthly_mean/ms_pres/ms_pres.ctl' )
      _var_pres.f = 'ms_pres.'_f2df.f+1
      f = f + 1
    endif
EOF
	    else
		cat >> ${TEMP_DIR}/cnf_${DESC_ftype}.gsf <<EOF
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
	    cat >> ${TEMP_DIR}/cnf_${DESC_ftype}.gsf <<EOF
    _save = '${HEAD}'
EOF
	fi
        #
        # common for all
	cat >> ${TEMP_DIR}/cnf_${DESC_ftype}.gsf <<EOF
    _fmax = f - 1
    _region = '${DESC_region}'
return
EOF

	if [ ${FLAG_GRADS} -eq 0 ] ; then
	    cd ${TEMP_DIR}
	    #
	    if [ "${RUN_MODE}" = "test" ] ; then
		cat cnf_${DESC_ftype}.gsf
		grads -lc "${DESC_ftype}.gs" | tee grads.log 2>&1
		exit
	    else
		grads -blcx "${DESC_ftype}.gs" | tee grads.log 2>&1
	    fi
	    #
	    ERROR=$( grep -i "error" grads.log )
	    ERROR=${ERROR}$( grep -i "all undefined values" grads.log )
	    ERROR=${ERROR}$( grep -i "Data Request Warning" grads.log )
	    if [ "${ERROR}" != "" ] ; then
		cp -r ../${TEMP_DIR} ../${TEMP_DIR}.save
		echo
		echo "error occurred!"
		echo "see ${TEMP_DIR}.save/grads.log for details"
		echo
		exit 1
	    fi
	    [ -f ${HEAD}.eps ] && eps2png.sh ${HEAD}.eps
	    cd - > /dev/null
	fi
        #
	mv ${TEMP_DIR}/${HEAD}.png ${TEMP_DIR}/grads.log ${TEMP_DIR}/cnf_${DESC_ftype}.gsf ${OUTPUT_DIR} || exit 1
	rm -f ${TEMP_DIR}/${HEAD}.eps
        #
        ##############################
	#
	let i=i+1
	LINE_LIST=()
    done # end of loop for parse_list
done

rm ${TEMP_DIR}/temp.txt
echo
echo "$0 normally finished ($(date))"
echo
exit
