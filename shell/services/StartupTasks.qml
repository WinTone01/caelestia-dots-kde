pragma Singleton

import QtQuick
import Quickshell.Io
import qs.utils

Item {
    id: root

    property Process initProcess: Process {
        command: ["bash", "-c", `
            INIT=$(kreadconfig6 --file kwinrc --group Plugins --key caelestiaMagicLampInit)
            if [[ -z "$INIT" ]]; then
                kwriteconfig6 --file kwinrc --group Plugins --key magiclampEnabled true 2>/dev/null || true
                kwriteconfig6 --file kwinrc --group Plugins --key squashEnabled false 2>/dev/null || true
                kwriteconfig6 --file kwinrc --group Plugins --key caelestiaMagicLampInit true 2>/dev/null || true
                qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
                echo "StartupTasks: Initialized Magic Lamp"
            fi
            
            # Future background installations or default settings can be appended here
        `]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    Logger.log(text.trim());
                }
            }
        }
    }
}
