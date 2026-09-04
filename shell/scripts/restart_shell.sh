#!/bin/bash

# If invoked from within Quickshell's systemd cgroup, or non-interactively without a TTY,
# escape to an independent transient service unit so systemd does not kill this script
# when Quickshell terminates.
if [ -z "$CAELESTIA_RESTART_DETACHED" ] && command -v systemd-run >/dev/null 2>&1; then
    if ! [ -t 1 ] || grep -qE "(caelestia|quickshell)" /proc/self/cgroup 2>/dev/null; then
        self="$(realpath "$0")"
        exec systemd-run --user --quiet --collect \
            --unit="caelestia-restart-$$" \
            --description="Caelestia Shell Restart Helper" \
            --setenv=CAELESTIA_RESTART_DETACHED=1 \
            "$self" "$@"
    fi
fi

# Stop any existing transient shell unit
systemctl --user stop caelestia-shell.service 2>/dev/null || true

/usr/bin/caelestia shell -k 2>/dev/null
sleep 1.3

if pgrep -x quickshell > /dev/null; then
    killall -w quickshell 2>/dev/null
fi
if pgrep -x qs > /dev/null; then
    killall -w qs 2>/dev/null
fi

# Wipe the stale Quickshell socket locks
rm -rf "${XDG_RUNTIME_DIR:-/run/user/$UID}/quickshell/"*

# Start the shell without handing it (and everything it launches) a stdout that
# goes nowhere. `caelestia shell -d` daemonizes, which points stdio at
# /dev/null, and the callers of this script redirect it there anyway - so a
# restart from the UI used to undo the fix that login gets right, until the
# next login. A transient user service is immune to both: systemd connects its
# stdio to the journal regardless of what this script was started with.
AUTOSTART_SCRIPT="$HOME/.local/bin/caelestia-autostart.sh"

if command -v systemd-run >/dev/null 2>&1; then
    systemctl --user reset-failed caelestia-shell.service 2>/dev/null || true
    if [ -x "$AUTOSTART_SCRIPT" ]; then
        systemd-run --user --quiet --collect --unit=caelestia-shell \
            --description="Caelestia Shell" \
            "$AUTOSTART_SCRIPT"
    else
        QS="$(command -v quickshell 2>/dev/null || command -v qs 2>/dev/null || echo /usr/bin/quickshell)"
        systemd-run --user --quiet --collect --unit=caelestia-shell \
            --description="Caelestia Shell" \
            -- "$QS" -n -p "$HOME/.config/quickshell/caelestia/shell.qml"
    fi
elif [ -x "$AUTOSTART_SCRIPT" ]; then
    "$AUTOSTART_SCRIPT" &
else
    /usr/bin/caelestia shell -d
fi
