#!/bin/bash -x
mqtt_args="-h 192.168.0.1 -p 1883 -u test -P test -t /room/rgbstrip/rgb"

xdialog() {
	Xdialog --title "RGB LED strip" --interval 100 --stdout "$@"
}

rgb() {
	printf "%02x%02x%02x\n" $1 $2 $3
}

rgb_hex() {
	printf "${1}${2}${3}\n"
}

hsv() {
	h=$1
	s=$2
	v=$3
	[[ $s == 0 ]] && {
		rgb $v $v $v
		return
	}

	local i=$[h/43]
	local rem=$[(h-(i*43))*6]
	local p=$[(v*(255-s))>>8]
	local q=$[(v*(255-((rem*s)>>8)))>>8]
	local t=$[(v*(255-(((255-rem)*s)>>8)))>>8]
	case $i in
		0)
			rgb $v $t $p
			;;
		1)
			rgb $q $v $p
			;;
		2)
			rgb $p $v $t
			;;
		3)
			rgb $p $q $v
			;;
		4)
			rgb $t $p $v
			;;
		*)
			rgb $v $p $q
			;;
	esac
}

case "$1" in
	w|white)
		xdialog --rangebox "Brightness" 10 100 \
			0 255 0 |
		while read v; do
			rgb $v $v $v
		done
		;;
	c|color)
		xdialog --colorsel "Color" 25 100 |
		while read r g b; do
			rgb $r $g $b
		done
		;;
	h|hsvcolor)
		re='([0-9]+)/([0-9]+)/([0-9]+)'
		xdialog --3rangesbox "Color" 25 100 \
			"Hue" 0 255 0 \
			"Saturation" 0 255 0 \
			"Value" 0 255 0 |
		while read v; do
			if [[ $v =~ $re ]]; then
				hsv ${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]}
			fi
		done
		;;
	m|midi)
		amidi -p hw:1,0,0 --dump |
		while read mtype mchan mval; do
			[[ $mtype != B0 ]] && continue
			mval=$[0x${mval}*2]
			[[ $mchan == $old_mchan && $mval == 0 ]] && continue
			delta=`sed 's#-##' <<<$[old_mval - mval]`
			[[ $delta -lt 5 ]] && continue
			case $mchan in
				01)
					h=$mval
					;;
				02)
					s=$mval
					;;
				03)
					v=$mval
					;;
			esac
			old_mchan=${mchan}
			old_mval=${mval}
			hsv $h $s $v
		done
		;;
	*)
		re='([0-9]+)/([0-9]+)/([0-9]+)'
		xdialog --3rangesbox "Color" 25 100 \
			"Red" 0 255 0 \
			"Green" 0 255 0 \
			"Blue" 0 255 0 |
		while read v; do
			if [[ $v =~ $re ]]; then
				rgb ${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]}
			fi
		done
		;;
esac |
while read str; do
	if [[ "$str" != "$old_str" ]]; then
		echo $str
		old_str=$str
		mosquitto_pub $mqtt_args -m $str
	fi
done
