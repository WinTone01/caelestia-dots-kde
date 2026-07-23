pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.effects
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import qs.modules.bar.components as BarComponents
import Quickshell.Services.UPower

PageBase {
    id: root

    title: qsTr("Toggle & rearrange")
    isSubPage: true
    scrollable: true

    readonly property var componentMeta: {
        "logo": { icon: "rocket_launch", name: qsTr("Logo") },
        "workspaces": { icon: "workspaces", name: qsTr("Workspaces") },
        "github": {
            icon: "commit",
            name: qsTr("GitHub"),
            available: BarComponents.GithubStore.available,
            unavailableText: qsTr("GitHub token not detected")
        },
        "activeWindow": { icon: "dock_to_right", name: qsTr("Active window") },
        "tray": { icon: "expand_more", name: qsTr("System tray") },
        "clock": { icon: "schedule", name: qsTr("Clock") },
        "statusIcons": { icon: "wifi", name: qsTr("Status icons") },
        "kbLayoutIndicator": { icon: "keyboard", name: qsTr("Keyboard layout") },
        "notificationsIndicator": { icon: "notifications", name: qsTr("Notifications") },
        "perfCpu": { icon: "memory", name: qsTr("CPU"), available: Cpu.name.length > 0, unavailableText: qsTr("CPU sensor not detected") },
        "perfMemory": { icon: "memory_alt", name: qsTr("Memory"), available: Memory.total > 1, unavailableText: qsTr("Memory sensor not detected") },
        "perfStorage": { icon: "hard_disk", name: qsTr("Storage"), available: Storage.disks.length > 0, unavailableText: qsTr("Storage disks not detected") },
        "perfNetwork": { icon: "swap_vert", name: qsTr("Network") },
        "perfGpu": { icon: "desktop_windows", name: qsTr("GPU"), available: Gpu.type !== Gpu.None, unavailableText: qsTr("GPU not detected") },
        "perfBattery": { icon: "battery_full", name: qsTr("Battery"), available: UPower.displayDevice.isLaptopBattery, unavailableText: qsTr("Battery not detected") },
        "dock": { icon: "apps", name: qsTr("Dock") },
        "power": { icon: "power_settings_new", name: qsTr("Power menu") }
    }

    readonly property real emptyZoneHeight: 72

    function load() {
        let entries = Config.bar.entries;
        leftModel.clear();
        middleModel.clear();
        rightModel.clear();
        libraryModel.clear();

        let activeCounts = {};
        for (let i = 0; i < entries.length; i++) {
            let entry = entries[i];
            if (entry.id === "spacer") continue;
            
            activeCounts[entry.id] = (activeCounts[entry.id] || 0) + 1;
            
            if (entry.enabled) {
                let zone = entry.zone || "left";
                if (zone === "left") leftModel.append({ "compId": entry.id, "isPlaceholder": false });
                else if (zone === "middle") middleModel.append({ "compId": entry.id, "isPlaceholder": false });
                else if (zone === "right") rightModel.append({ "compId": entry.id, "isPlaceholder": false });
            } else {
                libraryModel.append({ "compId": entry.id, "isPlaceholder": false });
            }
        }

        for (let key in componentMeta) {
            if (!activeCounts[key]) {
                libraryModel.append({ "compId": key, "isPlaceholder": false });
            }
        }
    }

    function defaultEntries() {
        return [
            { id: "logo", enabled: true, zone: "left" },
            { id: "workspaces", enabled: true, zone: "left" },
            { id: "activeWindow", enabled: true, zone: "left" },
            { id: "dock", enabled: true, zone: "middle" },
            { id: "tray", enabled: true, zone: "right" },
            { id: "github", enabled: true, zone: "right" },
            { id: "clock", enabled: true, zone: "right" },
            { id: "statusIcons", enabled: true, zone: "right" },
            { id: "kbLayoutIndicator", enabled: false, zone: "right" },
            { id: "notificationsIndicator", enabled: false, zone: "right" },
            { id: "perfCpu", enabled: false, zone: "right" },
            { id: "perfMemory", enabled: false, zone: "right" },
            { id: "perfStorage", enabled: false, zone: "right" },
            { id: "perfNetwork", enabled: false, zone: "right" },
            { id: "perfGpu", enabled: false, zone: "right" },
            { id: "perfBattery", enabled: false, zone: "right" },
            { id: "power", enabled: true, zone: "right" }
        ];
    }

    function resetToDefaults() {
        const entries = defaultEntries();
        GlobalConfig.bar.entries = entries;

        leftModel.clear();
        middleModel.clear();
        rightModel.clear();
        libraryModel.clear();

        for (const entry of entries) {
            if (!entry.enabled) {
                libraryModel.append({ compId: entry.id, isPlaceholder: false });
                continue;
            }

            const zone = entry.zone || "left";
            if (zone === "left")
                leftModel.append({ compId: entry.id, isPlaceholder: false });
            else if (zone === "middle")
                middleModel.append({ compId: entry.id, isPlaceholder: false });
            else
                rightModel.append({ compId: entry.id, isPlaceholder: false });
        }
    }

    function save() {
        let newEntries = [];
        
        for (let i = 0; i < leftModel.count; i++) {
            if (!leftModel.get(i).isPlaceholder) {
                newEntries.push({ id: leftModel.get(i).compId, enabled: true, zone: "left" });
            }
        }
        for (let i = 0; i < middleModel.count; i++) {
            if (!middleModel.get(i).isPlaceholder) {
                newEntries.push({ id: middleModel.get(i).compId, enabled: true, zone: "middle" });
            }
        }
        for (let i = 0; i < rightModel.count; i++) {
            if (!rightModel.get(i).isPlaceholder) {
                newEntries.push({ id: rightModel.get(i).compId, enabled: true, zone: "right" });
            }
        }
        for (let i = 0; i < libraryModel.count; i++) {
            if (!libraryModel.get(i).isPlaceholder) {
                newEntries.push({ id: libraryModel.get(i).compId, enabled: false, zone: "left" });
            }
        }
        
        GlobalConfig.bar.entries = newEntries;
    }

    Component.onCompleted: load()

    DragDropManager {
        id: dragDropManager
        models: ({
            "left": leftModel,
            "middle": middleModel,
            "right": rightModel,
            "library": libraryModel
        })
        dragParent: root.flickable.contentItem
    }

    RowLayout {
        ListModel { id: leftModel }
        ListModel { id: middleModel }
        ListModel { id: rightModel }
        ListModel { id: libraryModel }

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.large

        // Left Side: Active Components Zones
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            spacing: Tokens.spacing.medium

            Text {
                text: qsTr("Active components")
                font: Tokens.font.title.small
                color: Colours.palette.m3onSurface
            }

            Text {
                text: qsTr("Drag to rearrange or disable")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
            
            // Left Zone
            DragDropZone {
                Layout.fillWidth: true
                zoneId: "left"
                manager: dragDropManager
                model: leftModel
                emptyText: qsTr("Left Zone")
                delegate: root.panelDelegate
                minHeight: root.emptyZoneHeight
                rectColor: Colours.palette.m3surfaceContainer
            }
            
            // Middle Zone
            DragDropZone {
                Layout.fillWidth: true
                zoneId: "middle"
                manager: dragDropManager
                model: middleModel
                emptyText: qsTr("Middle Zone")
                delegate: root.panelDelegate
                minHeight: root.emptyZoneHeight
                rectColor: Colours.palette.m3surfaceContainer
            }
            
            // Right Zone
            DragDropZone {
                Layout.fillWidth: true
                zoneId: "right"
                manager: dragDropManager
                model: rightModel
                emptyText: qsTr("Right Zone")
                delegate: root.panelDelegate
                minHeight: root.emptyZoneHeight
                rectColor: Colours.palette.m3surfaceContainer
            }
        }

        // Right Side: Library
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
                        text: qsTr("Disabled components")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }

                Item { Layout.fillWidth: true }

                TextButton {
                    text: qsTr("RESET")
                    type: TextButton.Filled
                    ToolTip.text: qsTr("Restore the default taskbar component layout")
                    ToolTip.visible: hovered
                    onClicked: root.resetToDefaults()
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
            manager: dragDropManager
            isAvailable: (root.componentMeta[compId]?.available ?? true)
            sourceList: {
                if (ListView.view.model === leftModel) return "left";
                if (ListView.view.model === middleModel) return "middle";
                if (ListView.view.model === rightModel) return "right";
                return "library";
            }
            onDropped: root.save()

            MaterialIcon {
                text: root.componentMeta[compId]?.icon ?? "widgets"
                color: delegateRoot.sourceList !== "library" ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
            }
            
            Text {
                Layout.fillWidth: true
                text: {
                    const base = root.componentMeta[compId]?.name ?? compId;
                    if (delegateRoot.isAvailable)
                        return base;
                    const reason = root.componentMeta[compId]?.unavailableText ?? qsTr("Not detected");
                    return `${base} (${reason})`;
                }
                font: Tokens.font.body.small
                color: delegateRoot.sourceList !== "library" ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
            }

            MaterialIcon {
                text: "drag_indicator"
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }
}

