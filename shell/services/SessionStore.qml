pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import Caelestia.Config

Singleton {
    id: root

    readonly property string menuPath: Quickshell.env("HOME") + "/.config/quickshell/caelestia/session_entries.json"

    property var entries: []
    property var pendingEntries: []
    property bool loaded: false
    property bool loading: false
    property bool cacheValid: false
    property real loadStartedAt: 0
    property real saveStartedAt: 0

    function defaultEntries() {
        return [
            { id: "logout", label: qsTr("Log Out"), icon: Config.session.icons.logout || "logout", command: ["sh", "-c", "qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout 2>/dev/null"], enabled: true, type: "default" },
            { id: "shutdown", label: qsTr("Shut Down"), icon: Config.session.icons.shutdown || "power_settings_new", command: Config.session.commands.shutdown, enabled: true, type: "default" },
            { id: "dino_gif", label: qsTr("Dinosaur Animation"), icon: "animation", command: [], enabled: true, type: "default" },
            { id: "hibernate", label: qsTr("Hibernate"), icon: Config.session.icons.hibernate || "mode_night", command: Config.session.commands.hibernate, enabled: true, type: "default" },
            { id: "reboot", label: qsTr("Restart"), icon: Config.session.icons.reboot || "restart_alt", command: Config.session.commands.reboot, enabled: true, type: "default" }
        ];
    }

    function cloneEntries(value) {
        return JSON.parse(JSON.stringify(value));
    }

    function ensureLoaded(forceDisk) {
        if (loading) return;
        if (forceDisk !== true && cacheValid) return;

        loading = true;
        loadStartedAt = Date.now();
        readProc.running = true;
    }

    function save(newEntries) {
        pendingEntries = cloneEntries(newEntries);
        entries = cloneEntries(newEntries);
        loaded = true;
        cacheValid = true;

        saveStartedAt = Date.now();
        saveDebounce.restart();
    }

    Process {
        id: readProc

        command: ["sh", "-c", "cat \"" + root.menuPath + "\" 2>/dev/null || echo '[]'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let parsed = [];
                try {
                    if (text.trim().length > 0) {
                        parsed = JSON.parse(text);
                    }
                } catch (e) {}

                if (!parsed || parsed.length === 0) {
                    parsed = root.defaultEntries();
                }

                root.entries = root.cloneEntries(parsed);
                root.loaded = true;
                root.cacheValid = true;
                root.loading = false;

                const loadMs = root.loadStartedAt > 0 ? (Date.now() - root.loadStartedAt) : 0;
                console.log("[perf][SessionStore] load disk ms=" + loadMs + " entries=" + root.entries.length);
                root.loadStartedAt = 0;
            }
        }
    }

    Timer {
        id: saveDebounce
        interval: 180
        repeat: false
        onTriggered: writeProc.running = true
    }

    Process {
        id: writeProc

        property string jsonContent: ""
        command: [
            "python3",
            "-c",
            "import sys, os; p=sys.argv[1]; d=os.path.dirname(p); os.makedirs(d, exist_ok=True) if d else None; open(p, 'w').write(sys.argv[2])",
            root.menuPath,
            jsonContent
        ]

        onRunningChanged: {
            if (running) {
                writeProc.jsonContent = JSON.stringify(root.pendingEntries);
            } else if (root.saveStartedAt > 0) {
                const saveMs = Date.now() - root.saveStartedAt;
                console.log("[perf][SessionStore] save disk ms=" + saveMs + " entries=" + root.pendingEntries.length);
                root.saveStartedAt = 0;
            }
        }

        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    FileView {
        path: root.menuPath
        watchChanges: true
        printErrors: false

        onFileChanged: {
            if (writeProc.running) return;
            root.cacheValid = false;
            root.ensureLoaded(true);
        }
    }

    Component.onCompleted: ensureLoaded(true)
}
