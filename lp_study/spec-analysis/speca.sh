freqs="2412 2417 2422 2427 2432 2437 2442 2447 2452 2457 2462 2467 2472 
	5180 5200 5220 5240 5260 5280 5300 5320 5500 5520 5540 5560 5580 5600 
	5620 5640 5660 5680 5700 5745 5765 5785 5805 5825"

dir="spectrum-captures"
wdev="wlan0"
filter="MHz"

ts=$(date +%H:%M:%S)
name="$1"
dump_output="$dir/$ts-$name.speca.log"
png_output="$dir/$ts-$name.speca.png"

hop_freq() {
	i=1
	for f in $freqs; do
		echo "[$i]$(iw speca info| grep channel)"
		iw dev speca set freq $f 2>/dev/null
		sleep 3
		i=$(($i+1))
	done
}

plot() {
		echo "
		set title 'WiFi spectrum noise avarage'
		set boxwidth 0.5
		set style fill solid
		set xtics nomirror rotate by -45 font ',8'
		set ylabel '[%]'
		set xlabel 'Channel'
		plot \"$1\" using 1:3:xtic(2) with boxes title \"$2 signal avg.\"
		" | gnuplot -p
}

plot_to_png() {
	echo "
		set title 'WiFi spectrum noise avarage'
		set boxwidth 0.5
		set style fill solid
		set xtics nomirror rotate by -45 font ',8'
		set ylabel '[%]'
		set xlabel 'Channel'
		set terminal png size 1024,600 enhanced
		plot \"$1\" using 1:3:xtic(2) with boxes title \"$2 signal avg.\"" | gnuplot
}

dbm_to_linear() {
	min="-110"
	max="-35"
	x=$1
	echo "100*( (1/(($max-($min)))*$x) + ( 1 - ($max/($max-($min))) ))" | bc -l
}

draw() {
	echo "Drawing the signal plot from $dump_output"
	
	tmpfreqs="$(mktemp)"
	cat $dump_output | while read l; do
		signal="$(echo $l | awk '{print $7}' | tr -d [A-z])"
        freq=$(echo $l | awk '{print $4}')
		[ -z "$freq" -o -z "$signal" ] && continue
		echo "$freq $signal" >> $tmpfreqs
	done

	tmpavg="$(mktemp)"
	tmppkts="$(mktemp)"
	total_pkts=0
	t=0
	for f in $freqs; do
		avg=0
		c=0
		for d in $(cat $tmpfreqs | grep "^$f" | awk '{print $2}'); do
			avg=$(echo "$avg + $(dbm_to_linear $d)" | bc -l)
			c=$(($c+1))
		done
		[ "$c" == "0" ] && avg=0 || avg=$(echo "$avg/$c" | bc -l)
		echo "$f $avg" >> $tmpavg
		t=$(($t+1))
		echo "$f $c" >> $tmppkts
		total_pkts=$(($total_pkts + $c))
	done

	echo "Total number of packets is $total_pkts"

	# Normalizing
	pktsavg=0
	c=0
	for p in $(cat $tmppkts | awk '{print $2}'); do
		pktsavg=$(($pktsavg + $p))
		c=$(($c+1))
	done
	[ "$c" == 0 ] && pktsavg=1 || pktsavg=$(echo "$pktsavg/$c" | bc -l)

	echo "The packets average recived per chhannel is: $pktsavg"

	output="$(mktemp)"
	echo "Output file is: $output"

	norm_fact=$(echo "$pktsavg/$total_pkts" | bc -l)
	echo "Normalization factor is: $norm_fact"

	c=0
	cat $tmpavg | while read t; do
		freq=$(echo $t | awk '{print $1}')
		signal=$(echo $t | awk '{print $2}')
		normalized_signal=$(echo "${signal}*${norm_fact}" | bc -l)
		echo "$c $freq $normalized_signal" >> $output
		c=$(($c+1))
	done

	# Plotting
	plot_to_png $output "[$name]" > $png_output
	plot $output "[$name]"
	
	sleep 2

	rm -f $tmpfreqs
	rm -f $tmpavg
	rm -f $tmppkts
}

capture() {
	[ $(ps -ef | egrep -i "networkmanager|network-manager|wicd" -c) -gt 1 ] && {
		echo "Please, stop your Network Manager before start speca"
		exit 1
	}
	[ "$(whoami)" != "root" ] && {
		echo "Please run this script as root: sudo $0"
		exit 1
	}

	[ ! -d $dir ] && mkdir $dir
	[ ! -e "/sys/class/net/speca" ] && iw $wdev interface add speca type monitor
	ip link set $wdev down
	ip link set speca up

	echo "Starting tcpdump capture to $dump_output"
	tcpdump -i speca -n | grep $filter >> $dump_output &
	hop_freq

	killall tcpdump  2>/dev/null
}

capture
draw
