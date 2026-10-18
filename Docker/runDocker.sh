#!/bin/bash
if [ ! -f /opt/fpp/src/fppinit ]; then
    cd /opt/fpp/src
    CPUS=$(/opt/fpp/scripts/functions ComputeMakeParallelism)
    make -j ${CPUS}
fi

# Detect if running in a container and flag accordingly
if [ -f "/.dockerenv" ]
then
	echo "docker" > /etc/fpp/container
elif [ -f "/run/.containerenv" -o -f "/var/run/.containerenv" ]
then
	echo "podman" > /etc/fpp/container
elif [ -f "/etc/fpp/container" ]
then
	rm /etc/fpp/container
fi

/opt/fpp/src/fppinit start
/opt/fpp/scripts/fppd_start

# Packages are installed (see Dockerfile PACKAGE_LIST) but nothing in this
# entrypoint ever started them -- on bare-metal/Pi installs systemd does this,
# but a container has no init system to fall back on. Without them FPP's own
# status page flags "mDNS/Avahi client failure" (Warning ID: 43), and
# MultiSync/.local discovery don't work.
#
# /run is NOT tmpfs in this image (only /dev/shm is) -- a stale pidfile from
# the PREVIOUS container start survives a `docker restart` in the writable
# layer, and dbus-daemon refuses to start if it finds one. Must be cleared
# before every start, not just the first.
mkdir -p /var/run/dbus
rm -f /var/run/dbus/pid /run/avahi-daemon/pid
dbus-daemon --system --fork
avahi-daemon --daemonize

# Neither daemon is supervised: a crash is silent and permanent until the
# next container restart, and both log via syslog -- which doesn't exist in
# this container (no /dev/log, no syslog daemon), so even that silently goes
# nowhere. This loop detects and restarts either one, logging to a file that
# actually gets seen (it's under the bind-mounted media volume).
WATCHDOG_LOG=/home/fpp/media/logs/daemon-watchdog.log
(
    while true; do
        sleep 30
        if ! pgrep -x dbus-daemon >/dev/null; then
            echo "$(date -Is) dbus-daemon down, restarting" >> "$WATCHDOG_LOG"
            rm -f /var/run/dbus/pid
            dbus-daemon --system --fork
        fi
        if ! pgrep -x avahi-daemon >/dev/null; then
            echo "$(date -Is) avahi-daemon down, restarting" >> "$WATCHDOG_LOG"
            rm -f /run/avahi-daemon/pid
            avahi-daemon --daemonize
        fi
        if ! pgrep -x chronyd >/dev/null; then
            echo "$(date -Is) chronyd down, restarting" >> "$WATCHDOG_LOG"
            chronyd -x
        fi
    done
) &

# cron is installed but, like avahi/dbus above, nothing starts it -- without
# it, /etc/logrotate.d/fpp_apache2_logs and fpp_other_logs never run, and the
# bind-mounted media/logs/*.log grow unbounded on the host disk.
cron

# chronyd is installed but, same pattern again, never started -- FPP's own
# healthCheck requires `timedatectl` (needs systemd as PID 1, which this
# container doesn't have) OR a running chronyd to report time-sync status,
# so it always failed with "NTP daemon not running" regardless of whether
# the HOST's clock is correct.
#
# -x (don't adjust the system clock) is not a capability workaround here --
# it's the correct mode for network_mode: host. The container shares the
# host's actual kernel clock, which the host's own time-sync (e.g.
# systemd-timesyncd) already keeps correct; chronyd adjusting it too would
# just be two daemons fighting over the same clock. Track-and-report only.
chronyd -x
if ! pgrep -x chronyd >/dev/null; then
    echo "$(date -Is) chronyd failed to start" >> /home/fpp/media/logs/daemon-watchdog.log
fi

# Single source of truth for "what port is Apache actually on" for the shell
# scripts patched below (shell-overrides/*) -- read once here from the same
# ports.conf override that apache itself reads, not a second hardcoded value.
export FPP_WEB_PORT="$(grep -oP '^Listen \K[0-9]+' /etc/apache2/ports.conf 2>/dev/null | grep -v '^443$' | head -1)"
export FPP_WEB_PORT="${FPP_WEB_PORT:-80}"

mkdir /run/php
/usr/sbin/php-fpm8.4 --fpm-config /etc/php/8.4/fpm/php-fpm.conf
/usr/sbin/apache2ctl -D FOREGROUND
