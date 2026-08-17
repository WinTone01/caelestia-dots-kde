pragma ComponentBehavior: Bound

import org.kde.pipewire as Pipewire
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.Layouts
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.components.images
import qs.services
import qs.utils

Item {
    id: root

    property var cardItems: []
    property var activeInfoClient: null
    property var panels: null
    readonly property int activeWsId: typeof KWinWorkspaceState !== "undefined" ? KWinWorkspaceState.activeId : 1
    property bool ignoreNextSwitch: false
    property bool _initialized: false
    property bool isDragging: false
    // How much a hovered card grows. The grid reserves room for exactly this, so
    // keep the two in step.
    readonly property real hoverScale: 1.02
    // Keyboard selection within the page in view. -1 is "nothing picked yet",
    // which is how the overview opens: an outline before the user has chosen
    // anything reads as "this one is selected" and sends them looking for a
    // selection they never made.
    property int selectedIndex: -1
    readonly property var currentWindows: {
        if (typeof KWinWorkspaceState === "undefined" || listView.currentIndex < 0)
            return [];
        const wsList = KWinWorkspaceState.workspaces;
        if (listView.currentIndex >= wsList.length)
            return [];
        const wsId = wsList[listView.currentIndex].index;
        const all = typeof KWinActiveWindowBridge !== "undefined" ? KWinActiveWindowBridge.windowList : null;
        const out = [];
        if (all)
            for (let i = 0; i < all.length; ++i)
                if (all[i].workspace && (all[i].workspace.id === wsId || all[i].workspace.index === wsId))
                    out.push(all[i]);
        return out;
    }

    signal requestWindowInfo(var client)
    signal requestClose()

    function cycleSelection(backwards: bool): void {
        const n = root.currentWindows.length;
        if (n === 0)
            return;
        if (backwards)
            root.selectedIndex = root.selectedIndex <= 0 ? n - 1 : root.selectedIndex - 1;
        else
            root.selectedIndex = root.selectedIndex >= n - 1 ? 0 : root.selectedIndex + 1;
    }
    function activateSelected(): void {
        const wins = root.currentWindows;
        if (root.selectedIndex < 0 || root.selectedIndex >= wins.length)
            return;
        const addr = wins[root.selectedIndex].address;
        if (!addr)
            return;
        if (typeof KWinActiveWindowBridge !== "undefined")
            KWinActiveWindowBridge.focusWindow(addr);
        if (typeof KWinWorkspaceState !== "undefined" && listView.currentIndex >= 0)
            KWinWorkspaceState.switchTo(KWinWorkspaceState.workspaces[listView.currentIndex].index);
        root.requestClose();
    }
    function syncPage() {
        if (typeof KWinWorkspaceState === "undefined") return;
        for (let i = 0; i < KWinWorkspaceState.workspaces.length; ++i) {
            const wId = KWinWorkspaceState.workspaces[i].index;
            if (wId === activeWsId) {
                if (listView.currentIndex !== i) {
                    listView.currentIndex = i;
                    if (!root._initialized) listView.positionViewAtIndex(i, ListView.SnapPosition);
                }
                break;
            }
        }
        root.ignoreNextSwitch = false;
        ignoreTimer.stop();
        root._initialized = true;
    }

    onOpacityChanged: {
        if (opacity <= 0)
            selectedIndex = -1;
    }
    onActiveWsIdChanged: Qt.callLater(syncPage)
    Component.onCompleted: {
        if (typeof KWinWorkspaceState !== "undefined") {
            const count = KWinWorkspaceState.workspaces.length;
            for (let i = 0; i < count; ++i) {
                workspaceModel.append({});
            }
        } else {
            workspaceModel.append({});
        }
        Qt.callLater(syncPage);
    }

    Connections {
        function onCycleOverview(backwards) {
            if (root.opacity > 0)
                root.cycleSelection(backwards);
        }

        target: Visibilities
    }
    Shortcut {
        sequences: ["Return", "Enter"]
        enabled: root.opacity > 0
        onActivated: root.activateSelected()
    }
    Shortcut {
        sequences: ["Tab", "Right"]
        enabled: root.opacity > 0
        onActivated: root.cycleSelection(false)
    }
    Shortcut {
        sequences: ["Shift+Tab", "Left"]
        enabled: root.opacity > 0
        onActivated: root.cycleSelection(true)
    }
    ListModel {
        id: workspaceModel
    }
    Connections {
        function onWorkspacesChanged() {
            const newCount = KWinWorkspaceState.workspaces.length;
            while (workspaceModel.count < newCount) {
                workspaceModel.append({});
            }
            while (workspaceModel.count > newCount) {
                workspaceModel.remove(workspaceModel.count - 1);
            }
        }

        target: typeof KWinWorkspaceState !== "undefined" ? KWinWorkspaceState : null
    }
    ListView {
        id: listView

        anchors.fill: parent
        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        cacheBuffer: 100000 // Keep all pages instantiated to prevent drag-and-drop interruption
        interactive: !root.isDragging // Prevent ListView from stealing grab during drag
        preferredHighlightBegin: 0
        preferredHighlightEnd: 0
        highlightMoveDuration: root._initialized ? 250 : 0
        boundsBehavior: Flickable.StopAtBounds
        onCountChanged: Qt.callLater(root.syncPage)
        onCurrentIndexChanged: {
            if (root.ignoreNextSwitch) return;
            switchTimer.restart();
        }
        model: workspaceModel
        delegate: Item {
            id: page

            required property int index
            readonly property int wsId: typeof KWinWorkspaceState !== "undefined" ? KWinWorkspaceState.workspaces[index].index : index + 1
            readonly property string wsName: typeof KWinWorkspaceState !== "undefined" ? KWinWorkspaceState.workspaces[index].name : wsId.toString()
            readonly property var wsWindows: {
                const kwinList = typeof KWinActiveWindowBridge !== "undefined" ? KWinActiveWindowBridge.windowList : null;
                let arr = [];
                if (kwinList) {
                    for (let i = 0; i < kwinList.length; ++i) {
                        const w = kwinList[i];
                        if (w.workspace && (w.workspace.id === wsId || w.workspace.index === wsId)) {
                            arr.push(w);
                        }
                    }
                }
                return arr;
            }

            width: listView.width
            height: listView.height
            Component.onCompleted: {
                //console.log("WindowGrid Page initialized. wsId:", wsId, "windows found:", wsWindows.length, "Total windows globally:", typeof KWinActiveWindowBridge !== "undefined" ? KWinActiveWindowBridge.windowList.length : -1);
            }
            onWsWindowsChanged: {
                //console.log("WindowGrid Page updated. wsId:", wsId, "windows found:", wsWindows.length);
            }

            TapHandler {
                onTapped: root.requestClose()
            }
            DropArea {
                anchors.fill: parent
                onDropped: drop => {
                    const sourceItem = drop.source;
                    if (sourceItem && sourceItem.clientAddress) {
                        if (sourceItem.wsId !== undefined && sourceItem.wsId !== page.wsId) {
                            sourceItem.visible = false;
                            if (typeof KWinActiveWindowBridge !== "undefined") {
                                KWinActiveWindowBridge.setWindowDesktop(sourceItem.clientAddress, page.wsId);
                            } else {
                                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.movetoworkspace({ workspace = "${page.wsId}", window = "address:0x${sourceItem.clientAddress}" })` : `movetoworkspace ${page.wsId},address:0x${sourceItem.clientAddress}`);
                            }
                        }
                        drop.accept();
                    }
                }
            }
            Item {
                id: gridItem

                readonly property real hoverHeadroom: Math.ceil(Math.max(parent.width, parent.height) * (root.hoverScale - 1) / 2)
                property var windowLayout: Config.overview.layoutType === 0 ? LayoutKde.calculateLayout(page.wsWindows, width, height, Tokens.spacing.large, Tokens.spacing.large) : LayoutGnome.calculateLayout(page.wsWindows, width, height, Tokens.spacing.large, Tokens.spacing.large)

                // Opening the overview pulls the desktop into a rounded inset —
                // ContentWindow grows the border to 15% of the short edge — and
                // that inset is what reads as the stage. The layout fills whatever
                // area it is handed edge to edge, so hand it the stage rather than
                // the whole screen, or the outermost cards end up out on the black
                // frame, past the wallpaper they belong to. The border is the same
                // on all four sides (the workspace switcher lives out in the frame,
                // below it), so panels' own margins are the wrong thing to use here:
                // on whichever edge holds the bar, that margin is the bar's size
                // instead.
                anchors.fill: parent
                // Deliberately the settled border rather than the animating one:
                // laying out against a rect that is still growing means the first
                // layout lands on a nearly full-screen area and every card then
                // slides inward as it shrinks, which is the cards-flying-in-from-
                // everywhere effect on open. Sized to the destination, they are
                // simply in the right place from the first frame.
                //
                // Plus the headroom a hovered card needs to grow into. Without it
                // a card sitting on the edge of the stage grows straight off the
                // wallpaper, which is most obvious on the bottom row.
                anchors.margins: (root.panels ? root.panels.overviewBorderThickness : Tokens.padding.extraLarge) + hoverHeadroom

                Repeater {
                    model: page.wsWindows
                    delegate: StyledRect {
                        id: activeWin

                        required property var modelData
                        required property int index
                        readonly property string clientAddress: modelData.address
                        readonly property int wsId: page.wsId
                            readonly property var layoutProps: gridItem.windowLayout && gridItem.windowLayout[modelData.address] ? gridItem.windowLayout[modelData.address] : { x: 0, y: 0, width: 200, height: 150 }
                            readonly property real windowAspect: {
                                const w = modelData.width;
                                const h = modelData.height;
                                return (w > 0 && h > 0) ? (w / h) : (16.0 / 10.0);
                            }
                            // Only what the keyboard has picked, never "this is
                            // the window you were last in" — an outline on the
                            // latter reads as a selection the user did not make.
                            readonly property bool isSelected: page.index === listView.currentIndex && activeWin.index === root.selectedIndex
                            // Chrome stays out of the way until the card is the
                            // one being looked at. Cards this short lose the
                            // caption entirely; a title strip on a thumbnail that
                            // small costs more than it tells you.
                            readonly property bool showCaption: height > 96 && (hover.hovered || isSelected)

                            x: dragHandler.active ? x : layoutProps.x
                            y: dragHandler.active ? y : layoutProps.y
                            // The layout hands out boxes that tile the page without
                            // overlapping, so a card has to *be* its box. Sizing from
                            // content instead made every card wider and taller than
                            // its slot by the padding and the caption underneath it,
                            // which is what had them spilling over each other and off
                            // the page entirely.
                            width: layoutProps.width
                            height: layoutProps.height
                            color: Colours.tPalette.m3surfaceContainer
                            radius: Tokens.rounding.large
                            scale: (hover.hovered || activeWin.isSelected) && !dragHandler.active ? root.hoverScale : 1
                            border.width: activeWin.isSelected ? 2 : 0
                            border.color: Colours.palette.m3primary

                            Component.onCompleted: {
                                root.cardItems = [...root.cardItems, activeWin];
                            }
                            Component.onDestruction: {
                                root.cardItems = root.cardItems.filter(x => x !== activeWin);
                            }
                            states: [
                                State {
                                    when: dragHandler.active

                                    ParentChange {
                                        target: activeWin
                                        parent: root
                                    }
                                    PropertyChanges {
                                        target: activeWin
                                        opacity: 0.8
                                    }
                                }
                            ]

                            DragHandler {
                                id: dragHandler

                                onActiveChanged: {
                                    root.isDragging = active;
                                    if (!active) {
                                        let dropAction = activeWin.Drag.drop();
                                        if (dropAction !== Qt.IgnoreAction) {
                                            return; // Handled by DropArea
                                        }
                                        
                                        if (typeof KWinWorkspaceState === "undefined" || typeof KWinActiveWindowBridge === "undefined") return;
                                        const targetWsId = KWinWorkspaceState.workspaces[listView.currentIndex].index;
                                        if (targetWsId !== page.wsId) {
                                            activeWin.visible = false;
                                            KWinActiveWindowBridge.setWindowDesktop(clientAddress, targetWsId);
                                        }
                                    }
                                }
                            }
                            Behavior on scale { Anim {} }
                            Behavior on x { enabled: !dragHandler.active && root.opacity > 0.5; NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
                            Behavior on y { enabled: !dragHandler.active && root.opacity > 0.5; NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
                            HoverHandler { id: hover }
                            StateLayer {
                                anchors.fill: parent
                                radius: Tokens.rounding.large
                                onClicked: {
                                    if (modelData.address) {
                                        if (typeof KWinActiveWindowBridge !== "undefined") {
                                            KWinActiveWindowBridge.focusWindow(modelData.address);
                                        } else {
                                            Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ window = "address:0x${modelData.address}" })` : `focuswindow address:0x${modelData.address}`);
                                        }
                                        if (typeof KWinWorkspaceState !== "undefined") {
                                            KWinWorkspaceState.switchTo(page.wsId);
                                        }
                                    }
                                    const v = typeof Visibilities !== "undefined" ? Visibilities.getForActive() : null;
                                    if (v) v.overview = false;
                                }
                            }
                            ColumnLayout {
                                id: cardLayout

                                anchors.fill: parent
                                anchors.margins: Tokens.padding.small
                                spacing: Tokens.spacing.small

                                StyledClippingRect {
                                    id: thumb

                                    property var streamRequest: null
                                    readonly property int screencastSerial: streamRequest ? (streamRequest.objectSerial || streamRequest.nodeId) : 0

                                    function updateStream() {
                                        const isStolen = root.activeInfoClient && root.activeInfoClient.address === modelData.address;
                                        // Only the page in view and its immediate
                                        // neighbours, so a workspace three swipes
                                        // away is not being captured for nothing.
                                        const nearView = Math.abs(page.index - listView.currentIndex) <= 1;
                                        if (root.opacity > 0 && nearView && modelData.address && !isStolen) {
                                            if (!streamRequest) {
                                                streamRequest = ScreencastManager.requestStream(modelData.address);
                                            }
                                        } else {
                                            if (streamRequest) {
                                                ScreencastManager.releaseStream(modelData.address);
                                                streamRequest = null;
                                            }
                                        }
                                    }

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    color: Colours.tPalette.m3surfaceContainerHighest
                                    radius: Tokens.rounding.medium
                                    Component.onCompleted: updateStream()
                                    Component.onDestruction: {
                                        if (streamRequest && modelData.address) {
                                            ScreencastManager.releaseStream(modelData.address);
                                        }
                                    }

                                    Connections {
                                        function onOpacityChanged() {
                                            thumb.updateStream();
                                        }
                                        function onActiveInfoClientChanged() {
                                            thumb.updateStream();
                                        }

                                        target: root
                                    }
                                    Connections {
                                        function onCurrentIndexChanged() {
                                            thumb.updateStream();
                                        }

                                        target: listView
                                    }
                                    IconImage {
                                        anchors.centerIn: parent
                                        implicitSize: thumb.height * 0.5
                                        asynchronous: true
                                        visible: thumb.screencastSerial === 0
                                        source: modelData.iconName ? Icons.getAppIcon(modelData.iconName, "image-missing") : (modelData.class ? Icons.getAppIcon(modelData.class, "image-missing") : "")
                                    }
                                    Pipewire.PipeWireSourceItem {
                                        width: {
                                            const wAspect = activeWin.windowAspect;
                                            const containerAspect = thumb.width / Math.max(1, thumb.height);
                                            return (wAspect > containerAspect) ? thumb.width : thumb.height * wAspect;
                                        }
                                        height: {
                                            const wAspect = activeWin.windowAspect;
                                            const containerAspect = thumb.width / Math.max(1, thumb.height);
                                            return (wAspect > containerAspect) ? thumb.width / wAspect : thumb.height;
                                        }
                                        anchors.centerIn: parent
                                        visible: thumb.screencastSerial !== 0
                                        Component.onCompleted: {
                                        if ("objectSerial" in this) {
                                            this.objectSerial = Qt.binding(() => thumb.streamRequest ? thumb.streamRequest.objectSerial : 0)
                                        } else if ("nodeId" in this) {
                                            this.nodeId = Qt.binding(() => thumb.streamRequest ? thumb.streamRequest.nodeId : 0)
                                        }
                                    }
                                    }
                                    RowLayout {
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: Tokens.padding.small
                                        spacing: Tokens.spacing.small
                                        opacity: hover.hovered ? 1 : 0
                                        visible: opacity > 0.01

                                        Behavior on opacity { Anim {} }
                                        StyledRect {
                                            implicitWidth: infoIcon.implicitHeight + Tokens.padding.small * 2
                                            implicitHeight: infoIcon.implicitHeight + Tokens.padding.small * 2
                                            radius: Tokens.rounding.small
                                            color: Colours.palette.m3secondaryContainer

                                            StateLayer {
                                                anchors.fill: parent
                                                radius: Tokens.rounding.small
                                                onClicked: root.requestWindowInfo(modelData)
                                            }
                                            MaterialIcon {
                                                id: infoIcon

                                                anchors.centerIn: parent
                                                text: "chevron_right"
                                                color: Colours.palette.m3onSecondaryContainer
                                                fontStyle.pointSize: Tokens.font.body.medium.pointSize
                                            }
                                        }
                                        StyledRect {
                                            implicitWidth: closeIcon.implicitHeight + Tokens.padding.small * 2
                                            implicitHeight: closeIcon.implicitHeight + Tokens.padding.small * 2
                                            radius: Tokens.rounding.small
                                            color: Colours.palette.m3errorContainer

                                            StateLayer {
                                                anchors.fill: parent
                                                radius: Tokens.rounding.small
                                                onClicked: {
                                                    if (modelData.address) {
                                                        if (typeof KWinActiveWindowBridge !== "undefined") {
                                                            KWinActiveWindowBridge.closeWindow(modelData.address);
                                                        } else {
                                                            Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.close({ window = "address:0x${modelData.address}" })` : `closewindow address:0x${modelData.address}`);
                                                        }
                                                    }
                                                }
                                            }
                                            MaterialIcon {
                                                id: closeIcon

                                                anchors.centerIn: parent
                                                text: "close"
                                                color: Colours.palette.m3onErrorContainer
                                                fontStyle.pointSize: Tokens.font.body.medium.pointSize
                                            }
                                        }
                                    }
                                }
                                RowLayout {
                                    id: caption

                                    spacing: Tokens.spacing.small
                                    opacity: activeWin.showCaption ? 1 : 0
                                    visible: opacity > 0.01
                                    Layout.fillWidth: true
                                    Layout.leftMargin: Tokens.padding.extraSmall
                                    Layout.rightMargin: Tokens.padding.extraSmall

                                    IconImage {
                                        implicitSize: Math.round(titleText.implicitHeight * 1.1)
                                        asynchronous: true
                                        source: modelData.class ? Icons.getAppIcon(modelData.class, "image-missing") : ""
                                    }
                                    StyledText {
                                        id: titleText

                                        text: modelData.title || modelData.class || ""
                                        color: Colours.palette.m3onSurfaceVariant
                                        font: Tokens.font.body.small
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Behavior on opacity { Anim {} }
                                }
                            }
                            Drag.active: dragHandler.active
                            Drag.source: activeWin
                            Drag.hotSpot: dragHandler.centroid.position
                        }
                    }
                }
            }
        Timer {
            id: switchTimer

            interval: 50
            onTriggered: {
                if (typeof KWinWorkspaceState !== "undefined" && KWinWorkspaceState.workspaces.length > listView.currentIndex) {
                    const wId = KWinWorkspaceState.workspaces[listView.currentIndex].index;
                    if (KWinWorkspaceState.activeId !== wId) {
                        KWinWorkspaceState.switchTo(wId);
                    }
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: event => {
                if (!Config.bar.scrollActions.workspaces) return;
                
                if (event.angleDelta.y > 0 || event.angleDelta.x > 0) {
                    if (listView.currentIndex > 0) {
                        listView.currentIndex -= 1;
                    }
                } else if (event.angleDelta.y < 0 || event.angleDelta.x < 0) {
                    if (listView.currentIndex < listView.count - 1) {
                        listView.currentIndex += 1;
                    }
                }
            }
        }
        }
    StyledRect {
        id: indicatorContainer

        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin:Tokens.padding.large
        implicitWidth: workspaceIndicator.implicitWidth + Tokens.padding.large * 2
        implicitHeight: workspaceIndicator.implicitHeight + Tokens.padding.medium * 2
        radius: Tokens.rounding.large
        color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)

        WorkspaceIndicator {
            id: workspaceIndicator

            anchors.centerIn: parent
            maxWidth: Math.max(200, root.width - 100)
            count: listView.count
            currentIndex: listView.currentIndex
            onWorkspaceSelected: index => {
                root.ignoreNextSwitch = false;
                listView.currentIndex = index;
            }
            onWorkspaceReselected: root.requestClose()
            onCreateWorkspaceRequest: {
                root.ignoreNextSwitch = true;
                if (typeof KWinWorkspaceState !== "undefined") {
                    KWinWorkspaceState.createWorkspace();
                } else if (typeof Hypr !== "undefined") {
                    Hypr.dispatch("workspace empty");
                }
                ignoreTimer.restart();
            }
        }
    }
    Timer {
        id: ignoreTimer

        interval: 500
        onTriggered: root.ignoreNextSwitch = false
    }
    Timer {
        id: edgeScrollCooldown

        interval: 1000
    }
    DropArea {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 100
        onEntered: {
            if (!edgeScrollCooldown.running && listView.currentIndex > 0) {
                listView.currentIndex -= 1;
                edgeScrollCooldown.start();
            }
        }
    }
    DropArea {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 100
        onEntered: {
            if (!edgeScrollCooldown.running && listView.currentIndex < listView.count - 1) {
                listView.currentIndex += 1;
                edgeScrollCooldown.start();
            }
        }
    }
    StyledRect {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.large
        implicitWidth: prevIcon.implicitWidth + Tokens.padding.large * 2
        implicitHeight: prevIcon.implicitHeight + Tokens.padding.large * 2
        radius: height / 2
        color: Colours.tPalette.m3surfaceContainerHigh
        opacity: hoverPrev.hovered ? 1 : 0.6
        visible: listView.currentIndex > 0

        HoverHandler { id: hoverPrev }
        StateLayer {
            anchors.fill: parent
            radius: parent.radius
            onClicked: listView.currentIndex -= 1
        }
        MaterialIcon {
            id: prevIcon

            anchors.centerIn: parent
            text: "chevron_left"
            color: Colours.palette.m3onSurface
            fontStyle.pointSize: Tokens.font.body.large.pointSize
        }
    }
    StyledRect {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: Tokens.padding.large
        implicitWidth: nextIcon.implicitWidth + Tokens.padding.large * 2
        implicitHeight: nextIcon.implicitHeight + Tokens.padding.large * 2
        radius: height / 2
        color: Colours.tPalette.m3surfaceContainerHigh
        opacity: hoverNext.hovered ? 1 : 0.6
        visible: listView.currentIndex < listView.count - 1

        HoverHandler { id: hoverNext }
        StateLayer {
            anchors.fill: parent
            radius: parent.radius
            onClicked: listView.currentIndex += 1
        }
        MaterialIcon {
            id: nextIcon

            anchors.centerIn: parent
            text: "chevron_right"
            color: Colours.palette.m3onSurface
            fontStyle.pointSize: Tokens.font.body.large.pointSize
        }
    }
}
