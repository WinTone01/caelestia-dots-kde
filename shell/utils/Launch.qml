pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config

// How the shell starts other people's applications.
//
// Spawning them as plain children hands them the shell's own process context,
// and that context is not what an application should run in:
//
//   - stdio. The shell may have been started detached (`quickshell -d`,
//     `caelestia shell -d`), which points stdout and stderr at /dev/null.
//     Vesktop deadlocks when a call starts in exactly that state - issue #402,
//     reproducible on its own with `vesktop >/dev/null 2>&1`.
//   - environment. People deliberately start the shell with things stripped -
//     `env -u MANGOHUD -u MANGOHUD_CONFIG -u LD_PRELOAD caelestia shell -d` is
//     the usual MangoHud incantation, so the overlay does not land on the
//     shell itself. Every application launched from the shell then inherits
//     that stripped environment and loses the overlay too.
//   - lifetime. A child of the shell dies with the shell, and shares its
//     unit's OOMPolicy.
//
// Handing the launch to the systemd user manager fixes all three at once: it
// starts the application from the *session* environment rather than the
// shell's, with stdio on the journal, in its own unit.
Singleton {
    id: root

    // Set once the probe below has run. Until then launches use the plain
    // command, which is the old behaviour rather than a failure.
    property string launcher: ""

    /// Wraps a command so it starts outside the shell's process context.
    /// Returns the command unchanged when no launcher is available.
    function wrap(command: list<string>): list<string> {
        if (command.length === 0 || !GlobalConfig.services.useSystemd)
            return command;

        if (root.launcher === "app2unit")
            return ["app2unit", "-t", "service", "--", ...command];

        if (root.launcher === "systemd-run")
            return ["systemd-run", "--user", "--quiet", "--collect", "--", ...command];

        return command;
    }

    /// Launches a command, detached from the shell.
    function exec(command: list<string>): void {
        if (command.length > 0)
            Quickshell.execDetached(root.wrap(command));
    }

    /// Launches a desktop entry, honouring its working directory and its
    /// request to run in a terminal.
    function launchEntry(entry: DesktopEntry): void {
        if (entry.runInTerminal)
            Quickshell.execDetached({
                command: root.wrap([...GlobalConfig.general.apps.terminal, `${Quickshell.shellDir}/assets/wrap_term_launch.sh`, ...entry.command]),
                workingDirectory: entry.workingDirectory
            });
        else
            Quickshell.execDetached({
                command: root.wrap(entry.command),
                workingDirectory: entry.workingDirectory
            });
    }

    // app2unit knows how to name the unit after the desktop entry, which is
    // what the rest of the desktop expects to see; systemd-run is the fallback
    // because it ships with systemd itself.
    Process {
        running: true
        command: ["sh", "-c", "command -v app2unit >/dev/null 2>&1 && echo app2unit || { command -v systemd-run >/dev/null 2>&1 && echo systemd-run; }"]
        stdout: StdioCollector {
            onStreamFinished: root.launcher = text.trim()
        }
    }
}
