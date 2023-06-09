#!/usr/bin/env bash

function stop_cmd {
echo "Caught ${1}"
/usr/local/bin/user-management --save-persistent-users
exit 0
}

function stop_cmd_1 {
stop_cmd "SIGTERM"
}
function stop_cmd_2 {
stop_cmd "SIGQUIT"
}
function stop_cmd_3 {
stop_cmd "SIGINT"
}
function stop_cmd_4 {
stop_cmd "SIGHUP"
}
function stop_cmd_5 {
stop_cmd "ERR"
}
function stop_cmd_6 {
stop_cmd "SIGKILL"
}

trap stop_cmd_1 SIGTERM
trap stop_cmd_2 SIGQUIT
trap stop_cmd_3 SIGINT
trap stop_cmd_4 SIGHUP
trap stop_cmd_5 ERR
trap stop_cmd_6 SIGKILL

if [[ -z "${@}" ]]; then
	echo "Loading persistent users"
	/usr/local/bin/user-management --load-persistent-users
	if ! [[ -f /etc/cups/cupsd.conf ]]; then
		cp -rpn /etc/cups-skel/* /etc/cups/
	fi
	echo "Testing cupsd config"
	/usr/sbin/cupsd -t
	echo "Starting cupsd"
	/usr/sbin/cupsd -f
else
	"${@}"
fi
