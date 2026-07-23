import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import qs.components

StyledRect {
    id: zoneRoot
    
    required property string zoneId
    required property Item manager
    required property ListModel model
    required property string emptyText
    required property Component delegate
    
    property real minHeight: 72
    property real padding: Tokens.padding.medium
    property color rectColor: Colours.palette.m3surfaceContainer
    
    implicitHeight: Math.max(minHeight, listView.contentHeight + padding * 2)
    color: rectColor
    radius: Tokens.rounding.large
    
    Text {
        text: zoneRoot.emptyText
        font: Tokens.font.label.large
        color: Colours.palette.m3onSurfaceVariant
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Tokens.padding.small
        visible: zoneRoot.model.count === 0 || (zoneRoot.model.count === 1 && zoneRoot.model.get(0).isPlaceholder)
    }

    DropArea {
        anchors.fill: parent
        keys: ["component"]
        onEntered: drag => {
            let sourceItem = drag.source;
            if (!sourceItem) return;
            zoneRoot.manager.globalDragHoveredList = zoneRoot.zoneId;
            
            if (sourceItem.sourceList !== zoneRoot.zoneId) {
                let hasPlaceholder = false;
                for (let i = 0; i < zoneRoot.model.count; i++) {
                    if (zoneRoot.model.get(i).isPlaceholder) hasPlaceholder = true;
                }
                if (!hasPlaceholder) {
                    let obj = { compId: sourceItem.compId, isPlaceholder: true };
                    if (sourceItem.raw !== undefined) obj.raw = sourceItem.raw;
                    zoneRoot.model.append(obj);
                }
            }
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        anchors.margins: zoneRoot.padding
        orientation: ListView.Vertical
        spacing: Tokens.spacing.small
        model: zoneRoot.model
        clip: true

        move: Transition { NumberAnimation { properties: "y"; duration: 200; easing.type: Easing.OutCubic } }
        moveDisplaced: Transition { NumberAnimation { properties: "y"; duration: 200; easing.type: Easing.OutCubic } }
        delegate: zoneRoot.delegate
    }
}
