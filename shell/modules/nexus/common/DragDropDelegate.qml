import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.effects

Item {
    id: delegateWrapper
    
    required property int index
    required property string compId
    required property bool isPlaceholder
    property var raw: undefined
    property bool isAvailable: true
    
    required property Item manager
    required property string sourceList
    
    property bool isLibrary: sourceList === "library"
    
    signal dropped()
    
    default property alias content: contentRow.data
    
    width: ListView.view ? ListView.view.width : 0
    height: (manager.isGlobalDragging && manager.globalDragSourceList === sourceList && manager.globalDragSourceIndex === index && manager.globalDragHoveredList !== sourceList) ? 0 : 50
    visible: height > 0
    
    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    
    property bool isDraggingThis: activeDragArea.drag.active
    z: isDraggingThis ? 100 : 1

    DropArea {
        anchors.fill: parent
        keys: ["component"]
        onEntered: drag => {
            let sourceItem = drag.source;
            if (!sourceItem) return;
            
            let from = -1;
            let to = delegateWrapper.index;
            let targetModel = manager.getModel(sourceList);
            
            if (sourceItem.sourceList === sourceList) {
                from = manager.globalDragSourceIndex;
            } else {
                for (let i = 0; i < targetModel.count; i++) {
                    if (targetModel.get(i).isPlaceholder) { from = i; break; }
                }
            }
            
            if (from !== -1 && to !== -1 && from !== to) {
                targetModel.move(from, to, 1);
                if (sourceItem.sourceList === sourceList) {
                    manager.globalDragSourceIndex = to;
                }
            }
        }
    }

    StyledRect {
        id: activeDelegate
        width: delegateWrapper.width
        height: 50
        color: isDraggingThis ? Colours.layer(Colours.palette.m3surfaceContainerHighest, 2) : (!isLibrary ? Colours.palette.m3surfaceContainerHigh : Colours.palette.m3surfaceContainer)
        radius: Tokens.rounding.medium
        border.color: isDraggingThis ? Colours.palette.m3outline : (isLibrary ? Colours.palette.m3outlineVariant : "transparent")
        border.width: isDraggingThis ? 2 : (isLibrary ? 1 : 0)
        opacity: isPlaceholder ? 0.2 : (delegateWrapper.isAvailable ? 1.0 : 0.55)

        MouseArea {
            id: activeDragArea
            anchors.fill: parent
            hoverEnabled: true
            drag.target: isPlaceholder || !delegateWrapper.isAvailable ? null : activeDelegate
            drag.axis: Drag.XAndYAxis
            
            onPressed: {
                if (isPlaceholder || !delegateWrapper.isAvailable) return;
                manager.isGlobalDragging = true;
                manager.globalDragSourceList = sourceList;
                manager.globalDragSourceIndex = delegateWrapper.index;
                manager.globalDragHoveredList = sourceList;
            }
            
            onReleased: {
                if (isPlaceholder || !delegateWrapper.isAvailable) return;
                
                let finalHovered = manager.globalDragHoveredList;
                manager.isGlobalDragging = false;
                
                let targetModel = manager.getModel(finalHovered);
                let sourceModel = manager.getModel(sourceList);
                
                if (finalHovered !== sourceList && finalHovered !== "" && targetModel) {
                    let pIndex = -1;
                    for (let i = 0; i < targetModel.count; i++) {
                        if (targetModel.get(i).isPlaceholder) { pIndex = i; break; }
                    }
                    
                    if (pIndex !== -1) {
                        targetModel.remove(pIndex);
                        let obj = { compId: delegateWrapper.compId, isPlaceholder: false };
                        if (delegateWrapper.raw !== undefined) obj.raw = delegateWrapper.raw;
                        targetModel.insert(pIndex, obj);
                        sourceModel.remove(manager.globalDragSourceIndex);
                    }
                }
                
                manager.clearPlaceholders();
                
                activeDelegate.x = 0;
                activeDelegate.y = 0;
                delegateWrapper.dropped();
            }
        }

        StateLayer {
            anchors.fill: parent
            radius: Tokens.rounding.medium
            acceptedButtons: Qt.NoButton
            color: Colours.palette.m3onSurface
            opacity: activeDragArea.containsMouse && !isPlaceholder && !isDraggingThis ? 0.08 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        RowLayout {
            id: contentRow
            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.small
            visible: !isPlaceholder
        }

        Drag.active: activeDragArea.drag.active
        Drag.source: delegateWrapper
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2
        Drag.keys: ["component"]

        states: State {
            when: activeDragArea.drag.active
            ParentChange { target: activeDelegate; parent: manager.dragParent }
            PropertyChanges { target: activeDelegate; scale: 1.05 }
        }
    }
}
