#!/bin/bash

##############################
#   CONFIGURABLE VARIABLES   #
##############################

#Time (in seconds) between color changes.
CHANGERATE=60

#Min/max of a color's autogenerated int.
MIN=32
MAX=192

#Background image to load. Must have transparency for color to seep through.
IMAGE=~/projects/colorloop/boxes.png

#Internal file names, this is mostly useful if you want to put temporary files elsewhere.
LOCKCOLORFILE=~/projects/colorloop/.lock_color
CURRENTCOLORFILE=~/projects/colorloop/.current_color
FADETIMEFILE=~/projects/colorloop/.fade_time
CHANGERATEFILE=~/projects/colorloop/.change_rate

##############################
# END CONFIGURABLE VARIABLES #
##############################

VERSION=1.4

function help()
{
	echo "Desktop background colorloop script"
	echo "  version $VERSION by jokleinn"
	echo "Options:"
	echo "  -cint			Set change rate to a nondefault value."
	echo "  			  Set to -1 to disable."
	echo "  -fint			Fade color changes over a number of frames."
	echo "  			  Set to 1 to disable."
	echo "  -h			Show this help."
	echo "  -l			Lock the master color."
	echo " 				  Locking the master color will cause all"
	echo " 				  output to be deviations of it."
	echo "  -s\"int int int\"	Set the master color to the given 256-color integral rgb array."
	echo "  			  Example: -s\"32 64 192\""
	echo "  -u			Unlock the master color."
}

if [ $# -ne 0 ]
then
	while getopts :c:f:hls:u opt
	do
		case $opt in
			c)
				echo "$OPTARG" > "$CHANGERATEFILE"
				;;
			f)
				echo "$OPTARG" > "$FADETIMEFILE"
				;;
			h)
				help
				exit
				;;
			l)
				touch "$LOCKCOLORFILE"
				;;
			s)
				echo "$OPTARG" > "$CURRENTCOLORFILE"
				;;
			u)
				rm -f "$LOCKCOLORFILE"
				;;
			\?)
				echo "Invalid option: -$OPTARG" >&2
				exit 1
				;;
			:)
				echo "Option -$OPTARG requires an argument." >&2
				exit 1
				;;
		esac
	done
	exit
fi

#display(red, green, blue, gradient=null)
function display()
{
	red=$1
	green=$2
	blue=$3
	gradient=$4
	if [ "$gradient" = "" ] 
	then
		gradient=$(shuf -z -n1 -i20-40)
	fi
	hsetroot -add \#$(printf "%02X%02X%02X" $red $green $blue) -add \#$(printf "%02X%02X%02X" $blue $red $green) -add \#$(printf "%02X%02X%02X" $green $blue $red)  -gradient $gradient -full "$IMAGE"
}

#fade(oldr, oldg, oldb, red, green, blue, frames)
function fade()
{
	oldr=$1
	oldg=$2
	oldb=$3
	red=$4
	green=$5
	blue=$6
	frames=$7

	diffr=0
	let "diffr = $oldr - $red"
	let "modr = $diffr % $frames"
	let "diffr += $modr"
	let "incr = $diffr / $frames"
	let "incr *= -1"
	diffg=0
	let "diffg = $oldg - $green"
	let "modg = $diffg % $frames"
	let "diffg += $modg"
	let "incg = $diffg / $frames"
	let "incg *= -1"
	diffb=0
	let "diffb = $oldb - $blue"
	let "modb = $diffb % $frames"
	let "diffb += $modb"
	let "incb = $diffb / $frames"
	let "incb *= -1"

	gradient=$(shuf -z -n1 -i20-40)

	for i in $(seq 1 $frames)
	do
		let "addr = $incr * $i"
		let "addg = $incg * $i"
		let "addb = $incb * $i"
		if [ $i -eq $frames ]
		then
			display $red $green $blue $gradient
		else
			display $(($oldr + $addr)) $(($oldg + $addg)) $(($oldb + $addb)) $gradient
		fi
	done
}

while true; do
	colormin=$MIN
	colormax=$MAX
	dash="-"
	red=$(shuf -z -n1 -i$colormin$dash$colormax)
	green=$(shuf -z -n1 -i$colormin$dash$colormax)
	blue=$(shuf -z -n1 -i$colormin$dash$colormax)

	if [ -e "$CURRENTCOLORFILE" ]
	then
		color=$(cat "$CURRENTCOLORFILE")
		IFS=' ' read -a rgb <<< "$color"
	else
		echo "$red $green $blue" > "$CURRENTCOLORFILE"
		continue
	fi

	if [ -e "$LOCKCOLORFILE" ]
	then	
		red=${rgb[0]}
		green=${rgb[1]}
		blue=${rgb[2]}
	fi

	if [ -e "$FADETIMEFILE" ]
	then
		frames=$(cat "$FADETIMEFILE")
		if [ $frames -gt 0 ]
		then
			fade ${rgb[0]} ${rgb[1]} ${rgb[2]} $red $green $blue $frames
		fi
	else
		display $red $green $blue
	fi

	echo "$red $green $blue" > "$CURRENTCOLORFILE"


	sleeptime=$CHANGERATE
	if [ -e "$CHANGERATEFILE" ]
	then
		filechangerate=$(cat "$CHANGERATEFILE")	
		if [ $filechangerate -gt -1 ]
		then
			sleeptime=$filechangerate
		fi
	fi

	sleep $sleeptime
done
