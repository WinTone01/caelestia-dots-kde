pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.components.controls
import qs.services
import qs.modules.nexus.pages.wallandstyle
import qs.modules.nexus.common
import qs.utils

PageBase {
    id: root

    title: qsTr("Session Menu")
    isSubPage: true
    scrollable: true

    property var pendingSaveEntries: []
    property real perfLoadStartedAt: 0
    property real perfSaveStartedAt: 0
    readonly property real zonePadding: Tokens.padding.medium
    readonly property real emptyZoneHeight: Math.max(root.height - 120, 72)

    property var componentMeta: ({
        "logout": { icon: Config.session.icons.logout || "logout", name: qsTr("Log Out") },
        "shutdown": { icon: Config.session.icons.shutdown || "power_settings_new", name: qsTr("Shut Down") },
        "dino_gif": { icon: "animation", name: qsTr("Dinosaur Animation") },
        "hibernate": { icon: Config.session.icons.hibernate || "mode_night", name: qsTr("Hibernate") },
        "reboot": { icon: Config.session.icons.reboot || "restart_alt", name: qsTr("Restart") }
    })

    function getModel(name) {
        if (name === "active") return activeModel;
        if (name === "library") return libraryModel;
        return null;
    }

    function cloneEntries(entries) {
        return JSON.parse(JSON.stringify(entries));
    }

    function collectEntries() {
        let newEntries = [];
        for (let i = 0; i < activeModel.count; i++) {
            if (!activeModel.get(i).isPlaceholder) {
                let r = activeModel.get(i).rawEntry;
                r.enabled = true;
                newEntries.push(r);
            }
        }
        for (let i = 0; i < libraryModel.count; i++) {
            if (!libraryModel.get(i).isPlaceholder) {
                let r = libraryModel.get(i).rawEntry;
                r.enabled = false;
                newEntries.push(r);
            }
        }
        return newEntries;
    }

    function applyEntries(entries) {
        let json = (!entries || entries.length === 0) ? cloneEntries(SessionStore.defaultEntries()) : cloneEntries(entries);

        activeModel.clear();
        libraryModel.clear();

        for (let i = 0; i < json.length; i++) {
            let entry = json[i];
            if (entry.type === "custom") {
                root.componentMeta[entry.id] = { icon: (!entry.icon || entry.icon === "application-x-executable") ? "widgets" : entry.icon, name: entry.label };
            }
            if (entry.enabled) {
                activeModel.append({ "compId": entry.id, "isPlaceholder": false, "rawEntry": entry });
            } else {
                libraryModel.append({ "compId": entry.id, "isPlaceholder": false, "rawEntry": entry });
            }
        }
    }

    function flushSave() {
        if (!root.visible) return;
        const saveStartedAt = root.perfSaveStartedAt > 0 ? root.perfSaveStartedAt : Date.now();
        const payload = root.pendingSaveEntries.length > 0 ? root.pendingSaveEntries : collectEntries();
        SessionStore.save(payload);

        const saveMs = Date.now() - saveStartedAt;
        console.log("[perf][SessionPage] save queued ms=" + saveMs + " entries=" + payload.length);
        root.perfSaveStartedAt = 0;
    }

    function save() {
        if (!root.visible) return;
        root.pendingSaveEntries = collectEntries();
        root.perfSaveStartedAt = Date.now();
        saveDebounce.restart();
    }

    function load(forceDisk) {
        root.perfLoadStartedAt = Date.now();
        SessionStore.ensureLoaded(forceDisk === true);
        if (SessionStore.loaded && !SessionStore.loading) {
            root.applyEntries(SessionStore.entries);
            const source = forceDisk === true ? "store_disk" : "store_cache";
            const loadMs = Date.now() - root.perfLoadStartedAt;
            console.log("[perf][SessionPage] load source=" + source + " ms=" + loadMs + " entries=" + SessionStore.entries.length);
            root.perfLoadStartedAt = 0;
        }
    }

    Component.onCompleted: load(true)

    DragDropManager {
        id: dragDropManager
        models: ({ "active": activeModel, "library": libraryModel })
        dragParent: root.flickable.contentItem
    }

    RowLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.large

        Connections {
            target: SessionStore

            function onEntriesChanged() {
                root.applyEntries(SessionStore.entries);
                if (root.perfLoadStartedAt > 0) {
                    const loadMs = Date.now() - root.perfLoadStartedAt;
                    console.log("[perf][SessionPage] load source=store_update ms=" + loadMs + " entries=" + SessionStore.entries.length);
                    root.perfLoadStartedAt = 0;
                }
            }
        }

        Timer {
            id: saveDebounce
            interval: 180
            repeat: false
            onTriggered: root.flushSave()
        }

        AddShortcutDialog {
            id: addShortcutDialog
            onSaved: (label, cmd, icon) => {
                let id = "custom_" + Date.now();
                libraryModel.append({
                    compId: id,
                    isPlaceholder: false,
                    rawEntry: { id: id, type: "custom", label: label, command: ["sh", "-c", cmd], icon: icon, enabled: false }
                });
                root.componentMeta[id] = { name: label, icon: icon };
                root.save();
            }
        }

        ListModel { id: activeModel }
        ListModel { id: libraryModel }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            spacing: Tokens.spacing.medium

            Text {
                text: qsTr("Active menu items")
                font: Tokens.font.title.small
                color: Colours.palette.m3onSurface
            }

            Text {
                text: qsTr("Drag to rearrange or disable")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
            
            DragDropZone {
                Layout.fillWidth: true
                zoneId: "active"
                manager: dragDropManager
                model: activeModel
                emptyText: qsTr("Empty Menu")
                delegate: root.panelDelegate
                minHeight: root.emptyZoneHeight
                rectColor: Colours.palette.m3surfaceContainer
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                ColumnLayout {
                    spacing: 0
                    
                    Text {
                        text: qsTr("Library")
                        font: Tokens.font.title.small
                        color: Colours.palette.m3onSurface
                    }

                    Text {
                        text: qsTr("Disabled items")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }

                Item { Layout.fillWidth: true }

                TextButton {
                    text: qsTr("Add Shortcut...")
                    type: TextButton.Filled
                    ToolTip.text: qsTr("Create a custom shortcut entry")
                    ToolTip.visible: hovered
                    onClicked: {
                        addShortcutDialog.open();
                    }
                }
            }

            DragDropZone {
                Layout.fillWidth: true
                zoneId: "library"
                manager: dragDropManager
                model: libraryModel
                emptyText: qsTr("Empty")
                delegate: root.panelDelegate
                minHeight: root.emptyZoneHeight
                rectColor: "transparent"
            }
        }
    }

    property Component panelDelegate: Component {
        DragDropDelegate {
            id: delegateRoot
            raw: rawEntry
            manager: dragDropManager
            sourceList: ListView.view.model === activeModel ? "active" : "library"
            onDropped: root.save()

            Item {
                width: 24
                height: 24

                MaterialIcon {
                    anchors.fill: parent
                    visible: compId !== "dino_gif"
                    text: root.componentMeta[compId]?.icon || "widgets"
                    color: delegateRoot.sourceList !== "library" ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                }

                AnimatedImage {
                    anchors.fill: parent
                    visible: compId === "dino_gif"
                    playing: true
                    source: Paths.absolutePath(Config.paths.sessionGif !== "" ? Config.paths.sessionGif : "root:/assets/dino.gif")
                    fillMode: AnimatedImage.PreserveAspectFit

                    layer.enabled: true
                    layer.effect: Colouriser {
                        colorizationColor: delegateRoot.sourceList !== "library" ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                        sourceColor: "white"
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.componentMeta[compId]?.name || "Unknown Component"
                font: Tokens.font.body.small
                color: delegateRoot.sourceList !== "library" ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
            }
            
            TextButton {
                visible: delegateRoot.raw && delegateRoot.raw.type === "custom"
                text: qsTr("Delete")
                type: TextButton.Filled
                z: 100
                onClicked: {
                    if (delegateRoot.sourceList === "active") activeModel.remove(index);
                    else libraryModel.remove(index);
                    root.save();
                }
            }

            MaterialIcon {
                text: "drag_indicator"
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }
}

