#!/bin/bash -x
mqtt_args="-h 192.168.0.1 -p 1883 -u test -P test"
mqtt_topic="/rgbstrip/rgb"

xdialog() {
	Xdialog --title "RGB LED strip" --interval 100 --stdout "$@"
}

rgb() {
	printf "%02x%02x%02x\n" $1 $2 $3
}

rgb_hex() {
	printf "${1}${2}${3}\n"
}

hsv2rgb() {
	local h=${1}
	local s=$[${2}*255/100]
	local v=$[${3}*255/100]
	[[ $s -eq 0 ]] && {
		rgb $v $v $v
		return
	}

	local i=$[h/60]
	local vmin=$[(255-s)*v/255]
	local a=$[(v-vmin)*(h-(i*60))/60]
	local vinc=$[vmin+a]
	local vdec=$[v-a]
	case ${i%.} in
		0)
			rgb $v $vinc $vmin
			;;
		1)
			rgb $vdec $v $vmin
			;;
		2)
			rgb $vmin $v $vinc
			;;
		3)
			rgb $vmin $vdec $v
			;;
		4)
			rgb $vinc $vmin $v
			;;
		*)
			rgb $v $vmin $vdec
			;;
	esac
}

rgb2hsv() {
	r=$1
	g=$2
	b=$3

	max=$r
	[[ $g -gt $max ]] && max=$g
	[[ $b -gt $max ]] && max=$b
	
	min=$r
	[[ $g -lt $min ]] && min=$g
	[[ $b -lt $min ]] && min=$b
	
	if [[ $max -eq $min ]]; then
		h=0
	elif [[ $max -eq $r ]]; then
		t=$[60*(g-b)/(max-min)]
		h=$[(g>=b) ? t : (t+360)]
	elif [[ $max -eq $g ]]; then
		h=$[60*(b-r)/(max-min)+120]
	elif [[ $max -eq $b ]]; then
		h=$[60*(r-g)/(max-min)+240]
	else
		>&2 echo "wtf?"
	fi

	if [[ $max -eq '0' ]]; then
		s=0
	else
		s=$[100-((min*100)/max)]
	fi

	echo $h $s $[max*100/255]
}

r=0
g=0
b=0
old_rgb=`mosquitto_sub $mqtt_args -C 1 -t $mqtt_topic`
re='(..)(..)(..)'
if [[ $old_rgb =~ $re ]]; then
	r=$[0x${BASH_REMATCH[1]}]
	g=$[0x${BASH_REMATCH[2]}]
	b=$[0x${BASH_REMATCH[3]}]
fi

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
		hsv=`rgb2hsv $r $g $b`
		read h s v <<<"$hsv"
		re='([0-9]+)/([0-9]+)/([0-9]+)'
		xdialog --3rangesbox "Color" 25 100 \
			"Hue" 0 359 $h \
			"Saturation" 0 100 $s \
			"Value" 0 100 $v |
		while read v; do
			if [[ $v =~ $re ]]; then
				hsv2rgb ${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]}
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
			hsv2rgb $h $s $v
		done
		;;
	*)
		re='([0-9]+)/([0-9]+)/([0-9]+)'
		xdialog --3rangesbox "Color" 25 100 \
			"Red" 0 255 $r \
			"Green" 0 255 $g \
			"Blue" 0 255 $b |
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
		mosquitto_pub $mqtt_args -r -t $mqtt_topic -m $str
	fi
done
