export LANG=en

TEMP_DIR=""
function create_temp()
{
    for(( i=1; $i<=10; i=$i+1 ))
    do
        TEMP=`date +%s`
        TEMP_DIR=temp_${TEMP}
        [ ! -d ${TEMP_DIR} ] && break
        sleep 1s
    done
    mkdir ${TEMP_DIR}
}

function eps2png()
{
    EPS=$1
    PNG=`echo ${EPS} | sed -e "s/eps$/png/"`
#    convert -rotate 90 +antialias -depth 8 -define png:bit-depth=8 -density 600 -resize 915x700 ${EPS} temp.png
    convert -rotate 90 +antialias -depth 8 -define png:bit-depth=8 -density 600 -resize 854x660 ${EPS} temp.png
    convert -fill white -draw 'rectangle 0,0,10000,10000' temp.png white.png
    composite temp.png white.png ${PNG}
    rm temp.png white.png
}



function get_list_name
{
    FILE_LIST=$1
    if [ ! -f ${FILE_LIST} ] ; then
	echo "error: ${FILE_LIST} does not exist" >&2
	exit 1
    fi
    RET=( )
    NUM=$( cat ${FILE_LIST} | wc | awk '{ print $1 }' )
    FLAG=1
    for(( i=1; $i<=${NUM}; i=$i+1 ))
    do
        TMP=$( cat ${FILE_LIST} | sed -n ${i}p )
	[ "${TMP}" = "{" ] && FLAG=0 && continue
	[ "${TMP}" = "}" ] && FLAG=1 && continue

	[ ${FLAG} = 1 ] && RET=( ${RET[@]} ${TMP} )
    done
    echo ${RET[@]}
}
