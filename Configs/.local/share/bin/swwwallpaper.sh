#!/usr/bin/env sh


#// lock instance

lockFile="/tmp/hyde$(id -u)$(basename ${0}).lock"
[ -e "${lockFile}" ] && echo "An instance of the script is already running..." && exit 1
touch "${lockFile}"
trap 'rm -f ${lockFile}' EXIT


#// define functions

Wall_Links()
{
    if [ ! -e "${thmbDir}/${wallHash[setIndex]}.sqre" ] || [ ! -e "${thmbDir}/${wallHash[setIndex]}.thmb" ] || [ ! -e "${thmbDir}/${wallHash[setIndex]}.blur" ] || [ ! -e "${dcolDir}/${wallHash[setIndex]}.dcol" ] ; then
        "${scrDir}/swwwallcache.sh" -w "${walList[setIndex]}"
    fi

    "${scrDir}/swwwallbash.sh" "${walList[setIndex]}" &
    ln -fs "${walList[setIndex]}" "${wallSet}"
    ln -fs "${thmbDir}/${wallHash[setIndex]}.sqre" "${wallSqr}"
    ln -fs "${thmbDir}/${wallHash[setIndex]}.thmb" "${wallTmb}"
    ln -fs "${thmbDir}/${wallHash[setIndex]}.blur" "${wallBlr}"
    ln -fs "${dcolDir}/${wallHash[setIndex]}.dcol" "${wallDcl}"
}

Wall_Change()
{
    get_hashmap "${hydeThemeDir}"
    local curWall="$("${hashMech}" "${wallSet}" | awk '{print $1}')"
    for i in "${!wallHash[@]}" ; do
        if [ "${curWall}" == "${wallHash[i]}" ] ; then
            if [ "${1}" == "n" ] ; then
                setIndex=$(( (i + 1) % ${#walList[@]} ))
            elif [ "${1}" == "p" ] ; then
                setIndex=$(( i - 1 ))
            fi
            break
        fi
    done
    Wall_Links
}


#// set variables

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/globalcontrol.sh"
wallSet="${hydeThemeDir}/wall.set"
wallSqr="${cacheDir}/wall.sqre"
wallTmb="${cacheDir}/wall.thmb"
wallBlr="${cacheDir}/wall.blur"
wallDcl="${cacheDir}/wall.dcol"
setIndex=0


#// check wall

[ ! -d "${hydeThemeDir}" ] && echo "ERROR: \"${hydeThemeDir}\" does not exist" && exit 0
if [ ! -e "$(readlink -f "${wallSet}")" ] ; then
    get_hashmap "${hydeThemeDir}"
    echo "Fixing links :: ${hydeTheme} :: \"${walList[0]}\""
    ln -fs "${walList[setIndex]}" "${wallSet}"
fi


#// evaluate options

while getopts "nps:" option ; do
    case $option in
    n ) # set next wallpaper
        xtrans="grow"
        Wall_Change n
        ;;
    p ) # set previous wallpaper
        xtrans="outer"
        Wall_Change p
        ;;
    s ) # set input wallpaper
        if [ ! -z "${OPTARG}" ] && [ -f "${OPTARG}" ] ; then
            get_hashmap "${OPTARG}"
        fi
        Wall_Links
        ;;
    * ) # invalid option
        echo "... invalid option ..."
        echo "$(basename "${0}") -[option]"
        echo "n : set next wall"
        echo "p : set previous wall"
        echo "s : set input wallpaper"
        exit 1 ;;
    esac
done


#// check swww daemon and set wall

swww query
if [ $? -ne 0 ] ; then
    swww-daemon --format xrgb &
    sleep 1
    swww query
    if [ $? -ne 0 ] ; then
        swww clear-cache
        swww clear 
        swww init
        sleep 1
        swww query
        if [ $? -ne 0 ] ; then
            swww clear-cache
            swww clear 
            swww-daemon --format xrgb &
        fi
    fi
fi

echo ":: applying wall :: \"$(readlink -f "${wallSet}")\""
[ -z "${xtrans}" ] && xtrans="grow"
swww img "$(readlink "${wallSet}")" --transition-bezier .43,1.19,1,.4 --transition-type "${xtrans}" --transition-duration 0.4 --transition-fps 60 --invert-y --transition-pos "$( hyprctl cursorpos )" &
