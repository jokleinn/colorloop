#!/bin/bash

##############################
#   CONFIGURABLE VARIABLES   #
##############################

#Time (in seconds) between color changes.
CHANGERATE=60

#Background image to load. Must have transparency for color to seep through.
IMAGE=~/projects/colorloop/boxes.png

#Internal file names, this is mostly useful if you want to put temporary files elsewhere.
LOCKCOLORFILE=~/projects/colorloop/.lock_color
CURRENTCOLORFILE=~/projects/colorloop/.current_color

##############################
# END CONFIGURABLE VARIABLES #
##############################

VERSION=1.0

function help {
	echo "Desktop background colorloop script"
	echo "  version $VERSION by jokleinn"
	echo "Options:"
	echo "  -h			Show this help."
	echo "  -l			Lock the master color."
	echo " 				  Locking the master color will cause all"
	echo " 				  output to be deviations of it."
	echo "  -s\"int int int\"	Set the master color to the given 256-color integral array."
	echo "  -u			Unlock the master color."
}

if [ $# -ne 0 ]
then
	while getopts :hls:u opt
	do
		case $opt in
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

while true; do
	colormin=32
	colormax=192
	dash="-"
	red=$(shuf -z -n1 -i$colormin$dash$colormax)
	green=$(shuf -z -n1 -i$colormin$dash$colormax)
	blue=$(shuf -z -n1 -i$colormin$dash$colormax)

	if [ -e "$LOCKCOLORFILE" ]
	then
		color=$(cat "$CURRENTCOLORFILE")
		IFS=' ' read -a rgb <<< "$color"
		red=${rgb[0]}
		green=${rgb[1]}
		blue=${rgb[2]}
	fi

	hsetroot -add \#$(printf "%02X%02X%02X" $red $green $blue) -add \#$(printf "%02X%02X%02X" $blue $red $green) -add \#$(printf "%02X%02X%02X" $green $blue $red)  -gradient $(shuf -z -n1 -i20-40) -contrast 1.8 -blur 10 -full "$IMAGE"

	echo "$red $green $blue" > "$CURRENTCOLORFILE"

	sleep $CHANGERATE
done
