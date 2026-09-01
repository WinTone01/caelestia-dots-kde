pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import qs.components.misc
import qs.services

Scope {
    id: root

    property alias lock: lock

    function requestLock(): void {
        if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE"))
            lock.locked = true;
        else
            Quickshell.execDetached(["loginctl", "lock-session"]);
    }

    WlSessionLock {
        id: lock

        signal unlock

        onUnlock: Audio.playUnlock()

        onLockedChanged: {
            // Nothing needed here anymore since we play sounds explicitly
        }

        LockSurface {
            lock: lock
            pam: pam
        }
    }

    Pam {
        id: pam

        lock: lock
    }





    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "unlock"
        description: "Unlock the current session"
        onPressed: lock.unlock()
    }

    IpcHandler {
        function lock(): void {
            console.log("Lock IPC trigger received");
            root.requestLock();
            Audio.playLock();
        }

        function unlock(): void {
            lock.unlock();
        }

        function isLocked(): bool {
            return lock.locked;
        }

        target: "lock"
    }

    Timer {
        id: startupLockTimer

        interval: 750
        onTriggered: {
            if (GlobalConfig.lock.lockOnStartup) {
                root.requestLock();
            }
        }
    }

    Process {
        id: startupLockProc

        command: [
            "sh",
            "-c",
            "leader=$(loginctl show-session \"$XDG_SESSION_ID\" -p Leader --value 2>/dev/null); if [ -n \"$leader\" ]; then age=$(ps -o etimes= -p \"$leader\" | tr -d ' '); if [ -n \"$age\" ] && [ \"$age\" -lt 30 ]; then exit 0; else exit 1; fi; else age=$(awk '{print int($1)}' /proc/uptime); if [ -n \"$age\" ] && [ \"$age\" -lt 30 ]; then exit 0; else exit 1; fi; fi"
        ]
        onExited: code => {
            if (code === 0 && GlobalConfig.lock.lockOnStartup) {
                startupLockTimer.start();
            }
        }
    }

    Component.onCompleted: {
        if (GlobalConfig.lock.lockOnStartup) {
            startupLockProc.running = true;
        }
    }
}

