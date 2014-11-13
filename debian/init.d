#!/bin/sh
### BEGIN INIT INFO
# Provides:          powa
# Required-Start:    $local_fs $remote_fs $network $time
# Required-Stop:     $local_fs $remote_fs $network $time
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: PostgreSQL Workload Analyzer
# Description:       PoWA is a tool that gathers PostgreSQL performance stats and provides
#                    real-time charts and graphs to help monitor and tune your PostgreSQL
#                    servers.
### END INIT INFO

# Author: Ahmed Bessifi <ahmed.bessifi@gmail.com>

# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="PostgreSQL Workload Analyzer"
NAME=powa
SCRIPT=/usr/share/powa-ui/script/powa
SCRIPT_OPTS=""
PIDFILE=/var/run/$NAME.pid
LOG_DIR=/var/log/$NAME
LOG_FILE=${LOG_DIR}/${NAME}.log
SCRIPTNAME=/etc/init.d/$NAME

# Exit if the package is not installed
[ -x $DAEMON ] || exit 0

# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

export MOJO_LOG_LEVEL

# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

#
# Function that starts the daemon/service
#
do_start()
{
	# Returns :
	# 0 if daemon has been started
	# 1 if daemon was already running
	# 2 if daemon could not be started
	[ -f $PIDFILE ] && kill -s 0 `cat $PIDFILE` 2> /dev/null && return 1

	export PERL5LIB
	mkdir -p $LOG_DIR
	start-stop-daemon --start --quiet --pidfile $PIDFILE --background --startas /bin/bash -- -c "exec $DAEMON $DAEMON_OPTS $SCRIPT $SCRIPT_OPTS >> $LOG_FILE 2>&1" || return 2

}

#
# Function that stops the daemon/service
#
do_stop()
{
	# Returns :
	# 0 if daemon has been stopped
	# 1 if daemon was already stopped
	# 2 if daemon could not be stopped
	# other if a failure occurred
	start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PIDFILE
	RETVAL="$?"
	[ "$RETVAL" = 2 ] && return 2
	# sleep for some time.
	sleep 2
	# Many daemons don't delete their pidfiles when they exit.
	rm -f $PIDFILE
	NOW=$(date +"%a %b %e %T %Y")
	[ "$RETVAL" = 0 ] && echo "[$NOW] [info] Server stopped." >> $LOG_FILE
	return "$RETVAL"
}

case "$1" in
  start)
    [ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC " "$NAME"
    do_start
    case "$?" in
		0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
		2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
	esac
  ;;
  stop)
	[ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
	do_stop
	case "$?" in
		0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
		2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
	esac
	;;
  status)
	[ -f $PIDFILE ] && kill -s 0 `cat $PIDFILE` 2> /dev/null
	case "$?" in
		0) log_daemon_msg "is running" $NAME && log_end_msg 0 ;;
		1) log_daemon_msg "is not running" $NAME && log_end_msg 1 ;;
	esac
    ;;
  restart|force-reload)
	log_daemon_msg "Restarting $DESC" "$NAME"
	do_stop
	case "$?" in
	  0|1)
		do_start
		case "$?" in
			0) log_end_msg 0 ;;
			1) log_end_msg 1 ;; # Old process is still running
			*) log_end_msg 1 ;; # Failed to start
		esac
		;;
	  *)
	  	# Failed to stop
		log_end_msg 1
		;;
	esac
	;;
  *)
	echo "Usage: $SCRIPTNAME {start|stop|status|restart|force-reload}" >&2
	exit 3
	;;
esac

