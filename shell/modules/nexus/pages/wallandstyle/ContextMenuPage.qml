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
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Right Click Menu")
    isSubPage: true
    scrollable: true

    property var pendingSaveEntries: []
    property real perfLoadStartedAt: 0
    property real perfSaveStartedAt: 0
    readonly property real zonePadding: Tokens.padding.medium
    readonly property real emptyZoneHeight: Math.max(root.height - 120, 72)

    property var componentMeta: ({
        "toggle_desktop_icons": { icon: "desktop_windows", name: qsTr("Desktop Icons") },
        "wallpaper_style": { icon: "wallpaper", name: qsTr("Wallpaper & style") },
        "next_wallpaper": { icon: "skip_next", name: qsTr("Next Wallpaper") },
        "system_settings": { icon: "settings", name: qsTr("System Settings") },
        "open_terminal": { icon: "terminal", name: qsTr("Open Terminal") },
        "add_shortcut": { icon: "add", name: qsTr("Add Shortcut...") }
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
        let json = (!entries || entries.length === 0) ? cloneEntries(ContextMenuStore.defaultEntries()) : cloneEntries(entries);

        activeModel.clear();
        libraryModel.clear();

        for (let i = 0; i < json.length; i++) {
            let entry = json[i];
            if (entry.type === "custom") {
                root.componentMeta[entry.id] = { icon: entry.icon || "widgets", name: entry.label };
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
        ContextMenuStore.save(payload);
        root.componentMeta = root.componentMeta; // force update

        const saveMs = Date.now() - saveStartedAt;
        console.log("[perf][ContextMenuPage] save queued ms=" + saveMs + " entries=" + payload.length);
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
        ContextMenuStore.ensureLoaded(forceDisk === true);
        if (ContextMenuStore.loaded && !ContextMenuStore.loading) {
            root.applyEntries(ContextMenuStore.entries);
            const source = forceDisk === true ? "store_disk" : "store_cache";
            const loadMs = Date.now() - root.perfLoadStartedAt;
            console.log("[perf][ContextMenuPage] load source=" + source + " ms=" + loadMs + " entries=" + ContextMenuStore.entries.length);
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
            target: ContextMenuStore

            function onEntriesChanged() {
                root.applyEntries(ContextMenuStore.entries);
                if (root.perfLoadStartedAt > 0) {
                    const loadMs = Date.now() - root.perfLoadStartedAt;
                    console.log("[perf][ContextMenuPage] load source=store_update ms=" + loadMs + " entries=" + ContextMenuStore.entries.length);
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
                    rawEntry: { id: id, type: "custom", label: label, command: cmd, icon: icon, enabled: false }
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
            
            MaterialIcon {
                text: root.componentMeta[compId]?.icon || "widgets"
                color: delegateRoot.sourceList !== "library" ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
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

