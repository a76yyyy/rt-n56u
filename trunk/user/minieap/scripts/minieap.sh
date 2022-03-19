#!/bin/sh

pidfile="/var/run/minieap.pid"
[ -f $pidfile ] && kill -9 "$(cat $pidfile)" || echo "$$" > $pidfile

minieap_exec="minieap"
conf_file="/var/minieap.conf"
bin_conf_file="/etc/storage/minieap.conf"

minieap_vars="username password nic ip mask gw dns pinghost timeout interval \
	restart_wait maxfail startmode dhcp daemon ver datafile dhcpscript service"

minieap_conf_vars="Username Password Nic IP Mask Gateway DNS PingHost Timeout EchoInterval \
	RestartWait MaxFail StartMode DhcpMode DaemonMode Version DataFile DhcpScript Service"

func_log(){
	logger -st "minieap" "$1"
}

func_gen_conf(){
	if [ -z "$(nvram get minieap_nic)" ]; then
		nvram set minieap_nic="$(nvram get wan_ifname)"
		nvram commit
	fi

	echo "[MINIEAP]" > $conf_file
	for c in $minieap_conf_vars; do
		echo "${c}=" >> $conf_file
	done

	local line=2
	for c in $minieap_vars; do
		i="$(nvram get minieap_${c})"
		if [ -n "${i}" ]; then
			i="$(echo $i |sed 's/\//\\\//g')"
			sed -i "${line}s/\$/${i}/" $conf_file
		fi
		line=$((line+1))
	done

	ln -sf $conf_file $bin_conf_file
}

func_start(){
	if [ -f $bin_conf_file ] && [ ! -L $bin_conf_file ]; then
		func_log "Using existed conf: $bin_conf_file"
	else
		func_gen_conf
	fi

	echo -n "Starting minieap:..."
	start-stop-daemon -S -b -x "$minieap_exec"
	if [ $? -eq 0 ] ; then
		echo "[  OK  ]"
		func_log "Daemon is started"
	else
		echo "[FAILED]"
	fi
}

func_stop(){
	echo -n "Stopping minieap:..."
	killall -q -9 $minieap_exec
	echo "[  OK  ]"
	func_log "Stopped"
}

case "$1" in
start)
	func_start
	;;
stop)
	func_stop
	;;
restart)
	func_stop
	func_start
	;;
*)
	echo "Usage: $0 { start | stop | restart }"
	;;
esac
rm -f $pidfile
exit 0

