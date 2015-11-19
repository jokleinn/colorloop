#!/bin/bash

##############################
#   CONFIGURABLE VARIABLES   #
##############################

#Time (in seconds) between color changes.
CHANGERATE=60

#Time (in seconds) between frames.
FRAMELIMIT="0.2"

#Gradient mode. Set to 0 to use a solid color.
GRADIENT=1

#Min/max of a color's autogenerated int.
MIN=32
MAX=224

#Background image to load. Must have transparency for color to seep through.
IMAGE=snowflake.png
#IMAGE=boxes.png
#IMAGE=mosaiccircuit.png
#IMAGE=greenishspiral.png
#IMAGE=linus.png
#IMAGE=stallman.png
#IMAGE=patio.png
#IMAGE=gentoo_xfce_xmonad.png
#IMAGE=halloween.png

#Directory (under configuration directory) containing images.
IMAGEDIR=images

#"Configuration" directory. This will have a small handful of dot files thrown into it.
CONFDIR=/mnt/projects/git/colorloop

#Internal file names, this is mostly useful if you want to put temporary files elsewhere.
LOCKCOLORFILE=.lock_color
CURRENTCOLORFILE=.current_color
FADETIMEFILE=.fade_time
CHANGERATEFILE=.change_rate
IMAGEFILE=.current_image
GRADIENTFILE=.gradient
FRAMELIMITFILE=.framelimit

##############################
# END CONFIGURABLE VARIABLES #
##############################

VERSION=2.0

function help()
{
	echo "Desktop background colorloop script"
	echo "  version $VERSION by jokleinn"
	echo "Options:"
	echo "  -cint			Set change rate to a nondefault value."
	echo "  			  Set to -1 to make default, 0 to disable changerate."
	echo "  -fint			Fade color changes over a number of frames."
	echo "  			  Set to 1 to disable."
	echo "  -Ffloat			Set delay between two frames."
	echo "  -gint			Set use of gradients."
	echo "  -h			Show this help."
	echo "  -i\"filename\" 		Set the background image."
	echo "  -l			Lock the master color."
	echo " 				  Locking the master color will cause all"
	echo " 				  output to be deviations of it."
	echo "  -s\"int int int\"	Set the master color to the given 256-color integral rgb array."
	echo "  			  Example: -s\"32 64 192\""
	echo "  -u			Unlock the master color."
}

if [ $# -ne 0 ]
then
	while getopts :c:f:F:g:hi:ls:u opt
	do
		case $opt in
			c)
				if [ $OPTARG -gt -1 ]
				then
					echo "$OPTARG" > "$CONFDIR/$CHANGERATEFILE"
				else
					echo "Insane changerate value: $OPTARG"	>&2
				fi
				;;
			f)
				maxframes=32
				if [ $OPTARG -gt 0 ]
				then
					if [ $OPTARG -lt $(($maxframes+1)) ]
					then
						echo "$OPTARG" > "$CONFDIR/$FADETIMEFILE"
					else
						echo "Insane fade time frames: $OPTARG -- consider a value between 1 and $maxframes" >&2
				fi
				else
					echo "Insane fade time frames: $OPTARG -- consider a value between 1 and $maxframes" >&2
				fi
				;;
			F)
				echo "$OPTARG" > "$CONFDIR/$FRAMELIMITFILE"
				;;
			g)
				if [ $OPTARG -gt 0 ]
				then
					echo "1" > "$CONFDIR/$GRADIENTFILE"
				else
					echo "0" > "$CONFDIR/$GRADIENTFILE"
				fi
				;;
			h)
				help
				exit
				;;
			i)
				if [ -f "$CONFDIR/$IMAGEDIR/$OPTARG" ]
				then
					echo "$OPTARG" > "$CONFDIR/$IMAGEFILE"
				else
					echo "File does not exist: \"$OPTARG\"" >&2
				fi
				;;
			l)
				touch "$CONFDIR/$LOCKCOLORFILE"
				;;
			s)
				color=$OPTARG
				IFS=' ' read -a rgb <<< "$color"
				if [ ${rgb[0]} -gt -1 ] && [ ${rgb[0]} -lt 256 ] && [ ${rgb[1]} -gt -1 ] && [ ${rgb[1]} -lt 256 ] && [ ${rgb[2]} -gt -1 ] && [ ${rgb[2]} -lt 256 ]
				then
					echo "$OPTARG" > "$CONFDIR/$CURRENTCOLORFILE"
				else
					echo "Insane color value: $OPTARG" >&2
				fi
				;;
			u)
				rm -f "$CONFDIR/$LOCKCOLORFILE"
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
		gradient=$(shuf -z -n1 -i20-35)
	fi
	if [ $GRADIENT -eq 1 ]
	then
		hsetroot -add \#$(printf "%02X%02X%02X" $red $green $blue) -add \#$(printf "%02X%02X%02X" $blue $red $green) -add \#$(printf "%02X%02X%02X" $green $blue $red)  -gradient $gradient -full "$CONFDIR/$IMAGEDIR/$IMAGE"
	else
		hsetroot -solid \#$(printf "%02X%02X%02X" $red $green $blue) -full "$CONFDIR/$IMAGEDIR/$IMAGE"
	fi
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
		sleep $FRAMELIMIT
	done
}

while true; do
	colormin=$MIN
	colormax=$MAX
	dash="-"
	red=$(shuf -z -n1 -i$colormin$dash$colormax)
	green=$(shuf -z -n1 -i$colormin$dash$colormax)
	blue=$(shuf -z -n1 -i$colormin$dash$colormax)

	if [ -e "$CONFDIR/$IMAGEFILE" ]
	then
		IMAGE=$(cat "$CONFDIR/$IMAGEFILE")
		rm "$CONFDIR/$IMAGEFILE"
	fi

	if [ -e "$CONFDIR/$GRADIENTFILE" ]
	then
		GRADIENT=$(cat "$CONFDIR/$GRADIENTFILE")
		rm "$CONFDIR/$GRADIENTFILE"
	fi

	if [ -e "$CONFDIR/$FRAMELIMITFILE" ]
	then
		FRAMELIMIT=$(cat "$CONFDIR/$FRAMELIMITFILE")
		rm "$CONFDIR/$FRAMELIMITFILE"
	fi

	if [ -e "$CONFDIR/$CURRENTCOLORFILE" ]
	then
		color=$(cat "$CONFDIR/$CURRENTCOLORFILE")
		IFS=' ' read -a rgb <<< "$color"
	else
		echo "$red $green $blue" > "$CONFDIR/$CURRENTCOLORFILE"
		continue
	fi

	if [ -e "$CONFDIR/$LOCKCOLORFILE" ]
	then
		red=${rgb[0]}
		green=${rgb[1]}
		blue=${rgb[2]}
	fi

	if [ -e "$CONFDIR/$FADETIMEFILE" ]
	then
		frames=$(cat "$CONFDIR/$FADETIMEFILE")
		if [ $frames -ne 1 ]
		then
			fade ${rgb[0]} ${rgb[1]} ${rgb[2]} $red $green $blue $frames
		else
			display $red $green $blue
		fi
	else
		display $red $green $blue
	fi

	echo "$red $green $blue" > "$CONFDIR/$CURRENTCOLORFILE"


	sleeptime=$CHANGERATE
	if [ -e "$CONFDIR/$CHANGERATEFILE" ]
	then
		filechangerate=$(cat "$CONFDIR/$CHANGERATEFILE")
		if [ $filechangerate -gt -1 ]
		then
			sleeptime=$filechangerate
		fi
	fi

	sleep $sleeptime
done
