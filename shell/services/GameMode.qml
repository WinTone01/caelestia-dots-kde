pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.Services
import qs.services

Singleton {
    id: root

    property alias enabled: props.enabled

    // Hyprland is not always the compositor this runs under. Everything below
    // branches on that rather than assuming it.
    // Quickshell.env returns undefined for an unset variable, not "", so compare
    // truthiness — !== "" was true everywhere and sent KDE down the Hyprland path.
    readonly property bool onHyprland: !!Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")

    // Video wallpapers keep a decoder and a GPU upload running for as long as
    // they play, which is exactly what game mode is trying to free up.
    property bool restoreVideoWallpaper: false

    // ---- Auto-enable rules ----
    // The rules were editable in settings but nothing ever evaluated them, so
    // launching a listed game did nothing. Watch the open windows and match them.
    // Only a run that switched itself on switches itself back off, so a manual
    // toggle is never undone by a game closing.
    property bool autoEnabled: false

    readonly property var _windows: {
        if (typeof KWinActiveWindowBridge !== "undefined" && KWinActiveWindowBridge.windowList && KWinActiveWindowBridge.windowList.length > 0)
            return KWinActiveWindowBridge.windowList;
        return HyprlandData.windowList;
    }

    function _matchesRule(w): bool {
        const rules = GlobalConfig.utilities.gameMode.autoEnableRegexes || [];
        if (rules.length === 0 || !w)
            return false;
        const fields = [w.class || "", w.initialClass || "", w.title || ""];
        for (let i = 0; i < rules.length; i++) {
            const rule = String(rules[i] || "");
            if (rule === "")
                continue;
            for (let f = 0; f < fields.length; f++) {
                if (fields[f] === rule)
                    return true;          // plain name, the common case
                try {
                    if (new RegExp(rule).test(fields[f]))
                        return true;
                } catch (e) {
                    // A rule like "Minecraft* 1.21.11" is a window title, not a
                    // valid regex — the exact match above already covers it.
                }
            }
        }
        return false;
    }

    on_WindowsChanged: {
        const wins = root._windows || [];
        let matched = false;
        for (let i = 0; i < wins.length; i++)
            if (root._matchesRule(wins[i])) { matched = true; break; }

        if (matched && !root.enabled) {
            root.autoEnabled = true;
            root.enabled = true;
        } else if (!matched && root.enabled && root.autoEnabled) {
            root.autoEnabled = false;
            root.enabled = false;
        }
    }

    function setDynamicConfs(): void {
        Hypr.extras.applyOptions({
            "animations:enabled": 0,
            "decoration:shadow:enabled": 0,
            "decoration:blur:enabled": 0,
            "general:gaps_in": 0,
            "general:gaps_out": 0,
            "general:border_size": 1,
            "decoration:rounding": 0,
            "general:allow_tearing": 1
        });
    }

    // KWin's equivalents of the Hyprland options above: window animations and the
    // blur effect. Both are read back before being changed so a user who already
    // had them off does not get them switched on when game mode ends.
    //
    // The read-back has to happen at most once per game mode session, not once
    // per call. props.enabled is PersistentProperties-backed (reloadableId
    // "gameMode"), the same mechanism this codebase uses everywhere to survive a
    // Quickshell hot-reload — so a reload while game mode is already on restores
    // enabled: true into the freshly-constructed singleton, which fires
    // onEnabledChanged again with enabled === true. Without a guard, applyKwin(true)
    // would run its save step a second time, except by then kreadconfig6 reads back
    // game mode's *own* already-applied values (blur off, animations off) and
    // overwrites gamemode-prev with those — the user's real settings are gone, and
    // applyKwin(false) later "restores" them to off. props._prevSaved records that
    // the save already happened for this session; being on the same
    // PersistentProperties object, it survives the reload that would otherwise
    // retrigger the save.
    //
    // The general shape — toggle something, remember what it was before, put it
    // back later — recurs for any feature that temporarily overrides a KDE/Hyprland
    // setting. Guard the save step the same way: a PersistentProperties flag, set
    // once when the override begins and cleared only when it ends, rather than
    // assuming the "on" handler only ever runs once per session.
    function applyKwin(enable: bool): void {
        if (enable) {
            const saveStep = props._prevSaved ? "" :
                'prevBlur="$(kreadconfig6 --file kwinrc --group Plugins --key blurEnabled --default true)"; ' +
                'prevAnim="$(kreadconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor --default 1)"; ' +
                'mkdir -p "$HOME/.cache/caelestia"; printf "%s\\n%s\\n" "$prevBlur" "$prevAnim" > "$HOME/.cache/caelestia/gamemode-prev"; ';
            props._prevSaved = true;
            Quickshell.execDetached(["sh", "-c", saveStep +
                'kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled false; ' +
                'kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor 0; ' +
                'qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1']);
        } else {
            props._prevSaved = false;
            Quickshell.execDetached(["sh", "-c",
                'p="$HOME/.cache/caelestia/gamemode-prev"; ' +
                'blur="$(sed -n 1p "$p" 2>/dev/null)"; anim="$(sed -n 2p "$p" 2>/dev/null)"; ' +
                '[ -n "$blur" ] || blur=true; [ -n "$anim" ] || anim=1; ' +
                'kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled "$blur"; ' +
                'kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor "$anim"; ' +
                'qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1']);
        }
    }

    onEnabledChanged: {
        if (!enabled)
            root.autoEnabled = false;

        if (enabled) {
            // Pause a playing video wallpaper, remembering whether it was paused
            // already so ending game mode does not start one the user had stopped.
            root.restoreVideoWallpaper = !GlobalConfig.background.videoWallpaperPaused;
            if (root.restoreVideoWallpaper)
                GlobalConfig.background.videoWallpaperPaused = true;

            if (root.onHyprland)
                setDynamicConfs();
            else
                applyKwin(true);

            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Game mode enabled"),
                    root.onHyprland ? qsTr("Disabled Hyprland animations, blur, gaps and shadows")
                                    : qsTr("Paused video wallpaper, disabled blur and animations"), "gamepad");
        } else {
            if (root.restoreVideoWallpaper) {
                GlobalConfig.background.videoWallpaperPaused = false;
                root.restoreVideoWallpaper = false;
            }

            if (root.onHyprland)
                Hypr.extras.message("reload");
            else
                applyKwin(false);

            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Game mode disabled"),
                    root.onHyprland ? qsTr("Hyprland settings restored") : qsTr("Desktop effects restored"), "gamepad");
        }
    }

    PersistentProperties {
        id: props

        // Plain state, not a binding. It used to read back from
        // Hypr.options["animations:enabled"], which off Hyprland evaluates
        // undefined === 0 — false — so game mode could never stay switched on
        // there. onConfigReloaded below re-applies the options on Hyprland, so
        // nothing needed the binding anyway.
        property bool enabled: false

        // See applyKwin(): true once the previous KWin blur/animation state has
        // been captured for the current game mode session, so a reload while
        // still enabled does not re-capture (and corrupt) it from game mode's own
        // already-applied values. Reset when game mode turns off.
        property bool _prevSaved: false

        reloadableId: "gameMode"
    }

    Connections {
        function onConfigReloaded(): void {
            if (props.enabled)
                root.setDynamicConfs();
        }

        target: Hypr
    }

    IpcHandler {
        function isEnabled(): bool {
            return props.enabled;
        }

        function toggle(): void {
            props.enabled = !props.enabled;
        }

        function enable(): void {
            props.enabled = true;
        }

        function disable(): void {
            props.enabled = false;
        }

        target: "gameMode"
    }
}
