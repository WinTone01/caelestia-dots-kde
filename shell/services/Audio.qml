pragma Singleton

import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Caelestia
import Caelestia.Config
import Caelestia.Services

Singleton {
    id: root

    property string previousSinkName: ""
    property string previousSourceName: ""

    property list<PwNode> sinks: []
    property list<PwNode> sources: []
    property list<PwNode> streams: []

    // One representative stream per application, so no app ever appears twice
    // in the "Now playing" lists even when it opens multiple PipeWire streams.
    property list<PwNode> appStreams: []

    // The shell's own audio is already represented by the system volume, so it
    // must never show up as a separate app in the "Now playing" lists.
    readonly property string selfAppName: "caelestia-shell"

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    // The default node object is replaced whenever the graph moves - another
    // client adding a stream is enough - and a replacement arrives before its
    // description does. Reacting to the object meant announcing a device change
    // that never happened, sometimes as "Now using: Unknown Device", every time
    // something like OBS started (issue #402). Track the device's own name
    // instead, and say nothing until it is actually known.
    readonly property string sinkId: sink?.ready ? (sink.name ?? "") : ""
    readonly property string sourceId: source?.ready ? (source.name ?? "") : ""

    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0

    readonly property bool sourceMuted: !!source?.audio?.muted
    readonly property real sourceVolume: source?.audio?.volume ?? 0

    // CavaProvider is only registered when the plugin was built with libcava
    // available (see shell/plugin/CMakeLists.txt). Create it dynamically so a
    // build without Cava doesn't fail this whole singleton's component load.
    property var cava: null
    readonly property alias beatTracker: beatTracker

    function setVolume(newVolume: real): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function incrementVolume(amount: real): void {
        setVolume(volume + (amount || GlobalConfig.services.audioIncrement));
    }

    function decrementVolume(amount: real): void {
        setVolume(volume - (amount || GlobalConfig.services.audioIncrement));
    }

    function setSourceVolume(newVolume: real): void {
        if (source?.ready && source?.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function incrementSourceVolume(amount: real): void {
        setSourceVolume(sourceVolume + (amount || GlobalConfig.services.audioIncrement));
    }

    function decrementSourceVolume(amount: real): void {
        setSourceVolume(sourceVolume - (amount || GlobalConfig.services.audioIncrement));
    }

    function setAudioSink(newSink: PwNode): void {
        Pipewire.preferredDefaultAudioSink = newSink;
    }

    function setAudioSource(newSource: PwNode): void {
        Pipewire.preferredDefaultAudioSource = newSource;
    }

    function cycleNextAudioOutput(): void {
        if (sinks.length === 0)
            return;

        const currentIndex = sinks.findIndex(s => s === sink);
        const nextIndex = (currentIndex + 1) % sinks.length;
        setAudioSink(sinks[nextIndex]);
    }

    function setStreamVolume(stream: PwNode, newVolume: real): void {
        if (stream?.ready && stream?.audio) {
            stream.audio.muted = false;
            stream.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function setStreamMuted(stream: PwNode, muted: bool): void {
        if (stream?.ready && stream?.audio) {
            stream.audio.muted = muted;
        }
    }

    function getStreamVolume(stream: PwNode): real {
        return stream?.audio?.volume ?? 0;
    }

    function getStreamMuted(stream: PwNode): bool {
        return !!stream?.audio?.muted;
    }

    function getStreamName(stream: PwNode): string {
        if (!stream)
            return qsTr("Unknown");
        // Try application name first, then description, then name
        return stream.properties["application.name"] || stream.description || stream.name || qsTr("Unknown Application");
    }

    // App-level controls operate on every stream sharing the same app name, so a
    // single "caelestia-shell" row adjusts all of its streams together.
    function getAppVolume(stream: PwNode): real {
        if (!stream)
            return 0;

        const name = getStreamName(stream);
        let volume = 0;
        for (const s of root.streams) {
            if (getStreamName(s) === name && s?.audio)
                volume = Math.max(volume, s.audio.volume ?? 0);
        }
        return volume;
    }

    function getAppMuted(stream: PwNode): bool {
        if (!stream)
            return true;

        const name = getStreamName(stream);
        let hasStream = false;
        let allMuted = true;
        for (const s of root.streams) {
            if (getStreamName(s) !== name || !s?.audio)
                continue;
            hasStream = true;
            if (!s.audio.muted)
                allMuted = false;
        }
        return hasStream && allMuted;
    }

    function setAppVolume(stream: PwNode, newVolume: real): void {
        const name = getStreamName(stream);
        const clamped = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        for (const s of root.streams) {
            if (getStreamName(s) === name && s?.ready && s?.audio) {
                s.audio.muted = false;
                s.audio.volume = clamped;
            }
        }
    }

    function setAppMuted(stream: PwNode, muted: bool): void {
        const name = getStreamName(stream);
        for (const s of root.streams) {
            if (getStreamName(s) === name && s?.ready && s?.audio)
                s.audio.muted = muted;
        }
    }

    Component {
        id: sfxComponent

        SoundEffect {}
    }

    property var _sfxCache: ({})

    function playSoundSource(sourcePath: string, enabled: bool, volume: real): void {
        if (!GlobalConfig.audio.sounds.enabled || !enabled)
            return;
            
        let sfx = root._sfxCache[sourcePath];
        if (!sfx) {
            sfx = sfxComponent.createObject(root, { source: sourcePath, volume: volume });
            root._sfxCache[sourcePath] = sfx;
        } else {
            sfx.volume = volume;
        }
        sfx.play();
    }

    function playNotification(): void {
        playSoundSource(Qt.resolvedUrl("../assets/sounds/notifications/" + GlobalConfig.audio.sounds.notificationSound), true, GlobalConfig.audio.sounds.notificationVolume);
    }

    function playCameraClick(): void {
        playSoundSource(Qt.resolvedUrl("../assets/sounds/camera_click.wav"), GlobalConfig.audio.sounds.cameraClick, GlobalConfig.audio.sounds.sfxVolume);
    }

    function playChargingStarted(): void {
        playSoundSource(Qt.resolvedUrl("../assets/sounds/ChargingStarted.wav"), GlobalConfig.audio.sounds.chargingStarted, GlobalConfig.audio.sounds.sfxVolume);
    }

    function playEffectTick(): void {
        playSoundSource(Qt.resolvedUrl("../assets/sounds/Effect_Tick.wav"), GlobalConfig.audio.sounds.effectTick, GlobalConfig.audio.sounds.sfxVolume);
    }

    function playLock(): void {
        playSoundSource(Qt.resolvedUrl("../assets/sounds/Lock.wav"), GlobalConfig.audio.sounds.lock, GlobalConfig.audio.sounds.sfxVolume);
    }

    function playUnlock(): void {
        playSoundSource(Qt.resolvedUrl("../assets/sounds/Unlock.wav"), GlobalConfig.audio.sounds.unlock, GlobalConfig.audio.sounds.sfxVolume);
    }

    function playLowBattery(): void {
        playSoundSource(Qt.resolvedUrl("../assets/sounds/LowBattery.wav"), GlobalConfig.audio.sounds.lowBattery, GlobalConfig.audio.sounds.sfxVolume);
    }

    function playVideoRecord(): void {
        playSoundSource(Qt.resolvedUrl("../assets/sounds/VideoRecord.wav"), GlobalConfig.audio.sounds.screenRecord, GlobalConfig.audio.sounds.sfxVolume);
    }

    function playVideoStop(): void {
        playSoundSource(Qt.resolvedUrl("../assets/sounds/VideoStop.wav"), GlobalConfig.audio.sounds.screenRecord, GlobalConfig.audio.sounds.sfxVolume);
    }

    function refreshNodes(): void {
        const newSinks = [];
        const newSources = [];
        const newStreams = [];
        const newAppStreams = [];
        const seenApps = new Set();

        for (const node of Pipewire.nodes.values) {
            if (!node.isStream) {
                if (node.isSink)
                    newSinks.push(node);
                else if (node.audio)
                    newSources.push(node);
            } else if (node.audio) {
                newStreams.push(node);

                const name = getStreamName(node);
                if (name === root.selfAppName)
                    continue;
                if (!seenApps.has(name)) {
                    seenApps.add(name);
                    newAppStreams.push(node);
                }
            }
        }

        // Assign appStreams before streams so listeners of streamsChanged already
        // observe the deduplicated app list.
        root.appStreams = newAppStreams;
        root.sinks = newSinks;
        root.sources = newSources;
        root.streams = newStreams;
    }

    onSinkIdChanged: {
        if (!sinkId)
            return;

        const newSinkName = sink.description || sink.name;

        if (previousSinkName && previousSinkName !== newSinkName && GlobalConfig.utilities.toasts.audioOutputChanged)
            Toaster.toast(qsTr("Audio output changed"), qsTr("Now using: %1").arg(newSinkName), "volume_up");

        previousSinkName = newSinkName;
    }

    onSourceIdChanged: {
        if (!sourceId)
            return;

        const newSourceName = source.description || source.name;

        if (previousSourceName && previousSourceName !== newSourceName && GlobalConfig.utilities.toasts.audioInputChanged)
            Toaster.toast(qsTr("Audio input changed"), qsTr("Now using: %1").arg(newSourceName), "mic");

        previousSourceName = newSourceName;
    }

    // Populate immediately: Pipewire.nodes may already be filled by the time this
    // lazily-loaded singleton is created, so onValuesChanged would never fire.
    Component.onCompleted: {
        refreshNodes();
        // Seed only from a device that is actually known. A placeholder here
        // would read as the previous device and announce a change the moment
        // the real name arrived.
        previousSinkName = sinkId ? (sink.description || sink.name) : "";
        previousSourceName = sourceId ? (source.description || source.name) : "";

        // CavaProvider is only registered when the plugin was built with
        // libcava available (see shell/plugin/CMakeLists.txt); create it
        // dynamically so a build without Cava doesn't fail this singleton's load.
        try {
            root.cava = Qt.createQmlObject(
                'import Caelestia.Config\nimport Caelestia.Services\nCavaProvider { bars: GlobalConfig.services.visualiserBars }',
                root, "CavaProviderDynamic");
        } catch (e) {
            console.warn("Caelestia: CavaProvider unavailable, visualiser disabled:", e);
        }
    }

    Connections {
        function onValuesChanged(): void {
            root.refreshNodes();
        }

        target: Pipewire.nodes
    }

    // Always track the current defaults so volume/mute bind even if the lists
    // momentarily lag behind the default node.
    PwObjectTracker {
        objects: [root.sink, root.source, ...root.sinks, ...root.sources, ...root.streams].filter(n => n)
    }

    BeatTracker {
        id: beatTracker

        // Both providers feed off the same PipeWire capture of the sink
        // monitor. Disabling them here is what releases it: consumers keep
        // their references and their bindings, the capture simply stops.
        enabled: GlobalConfig.services.audioCapture
    }

    Binding {
        when: !!root.cava
        target: root.cava
        property: "enabled"
        value: GlobalConfig.services.audioCapture
    }


    IpcHandler {
        function cycleOutput(): void {
            root.cycleNextAudioOutput();
        }

        target: "audio"
    }

}
