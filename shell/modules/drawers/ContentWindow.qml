pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Blobs
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.bar

StyledWindow {
    id: root

    // Edit these variables to adjust how far the blur mask is inset from each logical edge.
    // They are relative to the widget's growth direction from the bar.
    property real blurOffsetTop: 0
    property real blurOffsetBottom: 0
    property real blurOffsetLeft: 0
    property real blurOffsetRight: 0

    component BlurRegion: Region {
        required property Item target
        property string vAnchor: "bottom" 
        property string hAnchor: "right"
        property real offsetScale: 0
        
        Config.screen: root.screen.name
        
        property bool isActive: target && target.visible && target.opacity > 0 && GlobalConfig.appearance.transparency.enabled && GlobalConfig.appearance.blur
        
        // Scale the offsets proportionally as the widget animates
        property real animScale: 1 - offsetScale
        
        // With a multi-rectangle mask, we don't need large offsets to hide sharp corners.
        // We can just use the user-defined base offsets directly.
        property real sTop: (vAnchor === "top" ? root.blurOffsetBottom : root.blurOffsetTop) * animScale
        property real sBottom: (vAnchor === "top" ? root.blurOffsetTop : root.blurOffsetBottom) * animScale
        property real sLeft: (hAnchor === "left" ? root.blurOffsetRight : root.blurOffsetLeft) * animScale
        property real sRight: (hAnchor === "left" ? root.blurOffsetLeft : root.blurOffsetRight) * animScale
        
        // Target tracking explicitly dependent on target geometry for fluid animation
        property real tX: {
            if (!target) return 0;
            let _ = target.x + target.width; // Dependency tracking
            return target.parent ? target.parent.mapToItem(root.contentItem, target.x, target.y).x : 0;
        }
        property real tY: {
            if (!target) return 0;
            let _ = target.y + target.height; // Dependency tracking
            return target.parent ? target.parent.mapToItem(root.contentItem, target.x, target.y).y : 0;
        }
        
        property real bX: tX + sLeft
        property real bY: tY + sTop
        property real bW: isActive ? Math.max(0, (target ? target.width : 0) - sLeft - sRight) : 0
        property real bH: isActive ? Math.max(0, (target ? target.height : 0) - sTop - sBottom) : 0
        
        property real r: Tokens.rounding.extraLarge * animScale
        property bool isIsland: GlobalConfig.appearance.islands
        
        // Dynamic corners depending on attachment anchor
        property real rTop: (!isIsland && vAnchor === "top") ? 0 : r
        property real rBottom: (!isIsland && vAnchor === "bottom") ? 0 : r
        property real rLeft: r
        property real rRight: r
        
        property real inLeft: bX + rLeft
        property real inRight: bX + bW - rRight
        property real inTop: bY + rTop
        property real inBottom: bY + bH - rBottom

        // Central and Edge Bodies (Strictly non-overlapping)
        Region { x: inLeft; y: inTop; width: Math.max(0, inRight - inLeft); height: Math.max(0, inBottom - inTop) } // Center
        Region { x: bX; y: inTop; width: Math.max(0, inLeft - bX); height: Math.max(0, inBottom - inTop) } // Left
        Region { x: inRight; y: inTop; width: Math.max(0, bX + bW - inRight); height: Math.max(0, inBottom - inTop) } // Right
        Region { x: inLeft; y: bY; width: Math.max(0, inRight - inLeft); height: Math.max(0, inTop - bY) } // Top
        Region { x: inLeft; y: inBottom; width: Math.max(0, inRight - inLeft); height: Math.max(0, bY + bH - inBottom) } // Bottom

        // Top-Left Corner (each strip extends to inTop — zero junction gap)
        Region { x: inLeft - rTop*0.9987 + 1; y: inTop - rTop*0.0500; width: rTop*0.9987; height: rTop*0.0500 }
        Region { x: inLeft - rTop*0.9950 + 1; y: inTop - rTop*0.1000; width: rTop*0.9950; height: rTop*0.1000 }
        Region { x: inLeft - rTop*0.9887 + 1; y: inTop - rTop*0.1500; width: rTop*0.9887; height: rTop*0.1500 }
        Region { x: inLeft - rTop*0.9798 + 1; y: inTop - rTop*0.2000; width: rTop*0.9798; height: rTop*0.2000 }
        Region { x: inLeft - rTop*0.9682 + 1; y: inTop - rTop*0.2500; width: rTop*0.9682; height: rTop*0.2500 }
        Region { x: inLeft - rTop*0.9539 + 1; y: inTop - rTop*0.3000; width: rTop*0.9539; height: rTop*0.3000 }
        Region { x: inLeft - rTop*0.9367 + 1; y: inTop - rTop*0.3500; width: rTop*0.9367; height: rTop*0.3500 }
        Region { x: inLeft - rTop*0.9165 + 1; y: inTop - rTop*0.4000; width: rTop*0.9165; height: rTop*0.4000 }
        Region { x: inLeft - rTop*0.8930 + 1; y: inTop - rTop*0.4500; width: rTop*0.8930; height: rTop*0.4500 }
        Region { x: inLeft - rTop*0.8660 + 1; y: inTop - rTop*0.5000; width: rTop*0.8660; height: rTop*0.5000 }
        Region { x: inLeft - rTop*0.8352 + 1; y: inTop - rTop*0.5500; width: rTop*0.8352; height: rTop*0.5500 }
        Region { x: inLeft - rTop*0.8000 + 1; y: inTop - rTop*0.6000; width: rTop*0.8000; height: rTop*0.6000 }
        Region { x: inLeft - rTop*0.7599 + 1; y: inTop - rTop*0.6500; width: rTop*0.7599; height: rTop*0.6500 }
        Region { x: inLeft - rTop*0.7141 + 1; y: inTop - rTop*0.7000; width: rTop*0.7141; height: rTop*0.7000 }
        Region { x: inLeft - rTop*0.6614 + 1; y: inTop - rTop*0.7500; width: rTop*0.6614; height: rTop*0.7500 }
        Region { x: inLeft - rTop*0.6000 + 1; y: inTop - rTop*0.8000; width: rTop*0.6000; height: rTop*0.8000 }
        Region { x: inLeft - rTop*0.5268 + 1; y: inTop - rTop*0.8500; width: rTop*0.5268; height: rTop*0.8500 }
        Region { x: inLeft - rTop*0.4359 + 1; y: inTop - rTop*0.9000; width: rTop*0.4359; height: rTop*0.9000 }
        Region { x: inLeft - rTop*0.3122 + 1; y: inTop - rTop*0.9500; width: rTop*0.3122; height: rTop*0.9500 }
        
        // Top-Right Corner (each strip extends to inTop — zero junction gap)
        Region { x: inRight; y: inTop - rTop*0.0500; width: rTop*0.9987; height: rTop*0.0500 }
        Region { x: inRight; y: inTop - rTop*0.1000; width: rTop*0.9950; height: rTop*0.1000 }
        Region { x: inRight; y: inTop - rTop*0.1500; width: rTop*0.9887; height: rTop*0.1500 }
        Region { x: inRight; y: inTop - rTop*0.2000; width: rTop*0.9798; height: rTop*0.2000 }
        Region { x: inRight; y: inTop - rTop*0.2500; width: rTop*0.9682; height: rTop*0.2500 }
        Region { x: inRight; y: inTop - rTop*0.3000; width: rTop*0.9539; height: rTop*0.3000 }
        Region { x: inRight; y: inTop - rTop*0.3500; width: rTop*0.9367; height: rTop*0.3500 }
        Region { x: inRight; y: inTop - rTop*0.4000; width: rTop*0.9165; height: rTop*0.4000 }
        Region { x: inRight; y: inTop - rTop*0.4500; width: rTop*0.8930; height: rTop*0.4500 }
        Region { x: inRight; y: inTop - rTop*0.5000; width: rTop*0.8660; height: rTop*0.5000 }
        Region { x: inRight; y: inTop - rTop*0.5500; width: rTop*0.8352; height: rTop*0.5500 }
        Region { x: inRight; y: inTop - rTop*0.6000; width: rTop*0.8000; height: rTop*0.6000 }
        Region { x: inRight; y: inTop - rTop*0.6500; width: rTop*0.7599; height: rTop*0.6500 }
        Region { x: inRight; y: inTop - rTop*0.7000; width: rTop*0.7141; height: rTop*0.7000 }
        Region { x: inRight; y: inTop - rTop*0.7500; width: rTop*0.6614; height: rTop*0.7500 }
        Region { x: inRight; y: inTop - rTop*0.8000; width: rTop*0.6000; height: rTop*0.8000 }
        Region { x: inRight; y: inTop - rTop*0.8500; width: rTop*0.5268; height: rTop*0.8500 }
        Region { x: inRight; y: inTop - rTop*0.9000; width: rTop*0.4359; height: rTop*0.9000 }
        Region { x: inRight; y: inTop - rTop*0.9500; width: rTop*0.3122; height: rTop*0.9500 }
        
        // Bottom-Left Corner (each strip extends from inBottom — zero junction gap)
        Region { x: inLeft - rBottom*0.9987; y: inBottom; width: rBottom*0.9987; height: rBottom*0.0500 }
        Region { x: inLeft - rBottom*0.9950; y: inBottom; width: rBottom*0.9950; height: rBottom*0.1000 }
        Region { x: inLeft - rBottom*0.9887; y: inBottom; width: rBottom*0.9887; height: rBottom*0.1500 }
        Region { x: inLeft - rBottom*0.9798; y: inBottom; width: rBottom*0.9798; height: rBottom*0.2000 }
        Region { x: inLeft - rBottom*0.9682; y: inBottom; width: rBottom*0.9682; height: rBottom*0.2500 }
        Region { x: inLeft - rBottom*0.9539; y: inBottom; width: rBottom*0.9539; height: rBottom*0.3000 }
        Region { x: inLeft - rBottom*0.9367; y: inBottom; width: rBottom*0.9367; height: rBottom*0.3500 }
        Region { x: inLeft - rBottom*0.9165; y: inBottom; width: rBottom*0.9165; height: rBottom*0.4000 }
        Region { x: inLeft - rBottom*0.8930; y: inBottom; width: rBottom*0.8930; height: rBottom*0.4500 }
        Region { x: inLeft - rBottom*0.8660; y: inBottom; width: rBottom*0.8660; height: rBottom*0.5000 }
        Region { x: inLeft - rBottom*0.8352; y: inBottom; width: rBottom*0.8352; height: rBottom*0.5500 }
        Region { x: inLeft - rBottom*0.8000; y: inBottom; width: rBottom*0.8000; height: rBottom*0.6000 }
        Region { x: inLeft - rBottom*0.7599; y: inBottom; width: rBottom*0.7599; height: rBottom*0.6500 }
        Region { x: inLeft - rBottom*0.7141; y: inBottom; width: rBottom*0.7141; height: rBottom*0.7000 }
        Region { x: inLeft - rBottom*0.6614; y: inBottom; width: rBottom*0.6614; height: rBottom*0.7500 }
        Region { x: inLeft - rBottom*0.6000; y: inBottom; width: rBottom*0.6000; height: rBottom*0.8000 }
        Region { x: inLeft - rBottom*0.5268; y: inBottom; width: rBottom*0.5268; height: rBottom*0.8500 }
        Region { x: inLeft - rBottom*0.4359; y: inBottom; width: rBottom*0.4359; height: rBottom*0.9000 }
        Region { x: inLeft - rBottom*0.3122; y: inBottom; width: rBottom*0.3122; height: rBottom*0.9500 }
        
        // Bottom-Right Corner (each strip extends from inBottom — zero junction gap)
        Region { x: inRight; y: inBottom; width: rBottom*0.9987; height: rBottom*0.0500 }
        Region { x: inRight; y: inBottom; width: rBottom*0.9950; height: rBottom*0.1000 }
        Region { x: inRight; y: inBottom; width: rBottom*0.9887; height: rBottom*0.1500 }
        Region { x: inRight; y: inBottom; width: rBottom*0.9798; height: rBottom*0.2000 }
        Region { x: inRight; y: inBottom; width: rBottom*0.9682; height: rBottom*0.2500 }
        Region { x: inRight; y: inBottom; width: rBottom*0.9539; height: rBottom*0.3000 }
        Region { x: inRight; y: inBottom; width: rBottom*0.9367; height: rBottom*0.3500 }
        Region { x: inRight; y: inBottom; width: rBottom*0.9165; height: rBottom*0.4000 }
        Region { x: inRight; y: inBottom; width: rBottom*0.8930; height: rBottom*0.4500 }
        Region { x: inRight; y: inBottom; width: rBottom*0.8660; height: rBottom*0.5000 }
        Region { x: inRight; y: inBottom; width: rBottom*0.8352; height: rBottom*0.5500 }
        Region { x: inRight; y: inBottom; width: rBottom*0.8000; height: rBottom*0.6000 }
        Region { x: inRight; y: inBottom; width: rBottom*0.7599; height: rBottom*0.6500 }
        Region { x: inRight; y: inBottom; width: rBottom*0.7141; height: rBottom*0.7000 }
        Region { x: inRight; y: inBottom; width: rBottom*0.6614; height: rBottom*0.7500 }
        Region { x: inRight; y: inBottom; width: rBottom*0.6000; height: rBottom*0.8000 }
        Region { x: inRight; y: inBottom; width: rBottom*0.5268; height: rBottom*0.8500 }
        Region { x: inRight; y: inBottom; width: rBottom*0.4359; height: rBottom*0.9000 }
        Region { x: inRight; y: inBottom; width: rBottom*0.3122; height: rBottom*0.9500 }
    }
    
    Config.screen: screen.name

    BackgroundEffect.blurRegion: Region {
        Region { x: -10; y: -10; width: 1; height: 1 } // Prevent fallback to full-window blur when empty
        
        BlurRegion { 
            target: bar
            vAnchor: Config.bar.position === "top" ? "top" : "bottom"
            hAnchor: Config.bar.position === "left" ? "left" : "right"
        }
        BlurRegion { 
            target: panels.sidebar
            vAnchor: "bottom"
            hAnchor: Config.bar.position === "right" ? "left" : "right"
            offsetScale: panels.sidebar.offsetScale
        }
        BlurRegion { 
            target: panels.notifications
            vAnchor: Config.bar.position === "bottom" ? "bottom" : "top"
            hAnchor: Config.bar.position === "right" ? "left" : "right"
            offsetScale: panels.notifications.offsetScale
        }
        BlurRegion { 
            target: panels.osdWrapper
            vAnchor: "top"
            hAnchor: Config.bar.position === "right" ? "left" : "right"
            offsetScale: panels.osd.offsetScale
        }
        BlurRegion { 
            target: panels.sessionWrapper
            vAnchor: "bottom"
            hAnchor: Config.bar.position === "right" ? "left" : "right"
            offsetScale: panels.session.offsetScale
        }
        BlurRegion { 
            target: panels.launcher
            vAnchor: "bottom"
            hAnchor: "right"
            offsetScale: panels.launcher.offsetScale
        }
        BlurRegion { 
            target: panels.dashboard
            vAnchor: "top"
            hAnchor: "right"
            offsetScale: panels.dashboard.offsetScale
        }
        BlurRegion { 
            target: panels.popoutsWrapper
            vAnchor: Config.bar.position === "top" ? "top" : "bottom"
            hAnchor: Config.bar.position === "left" ? "left" : "right"
            offsetScale: panels.popoutsWrapper.offsetScale
        }
        BlurRegion { 
            target: panels.utilities
            vAnchor: Config.bar.position === "bottom" ? "top" : "bottom"
            hAnchor: Config.bar.position === "right" ? "left" : "right"
            offsetScale: panels.utilities.offsetScale
        }
        BlurRegion { 
            target: panels.toasts
            vAnchor: "bottom"
            hAnchor: Config.bar.position === "bottom" ? "left" : (Config.bar.position === "right" ? "left" : "right")
        }
    }

    readonly property alias bar: bar
    readonly property alias interactionWrapper: interactions

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property bool hasSpecialWorkspace: (monitor?.lastIpcObject.specialWorkspace?.name.length ?? 0) > 0
    readonly property bool hasFullscreenOnNormalWs: monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false
    readonly property bool hasFullscreen: {
        if (hasSpecialWorkspace) {
            const specialName = monitor?.lastIpcObject.specialWorkspace?.name;
            if (!specialName)
                return false;
            const specialWs = Hypr.workspaces.values.find(ws => ws.name === specialName);
            return specialWs?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
        }
        return hasFullscreenOnNormalWs;
    }

    property real fsTransitionProg: hasFullscreen ? 1 : 0
    readonly property real sdfBorderOffset: 2 * fsTransitionProg // SDFs joins are not exact, so offset by 2px to ensure nothing shows
    readonly property real borderThickness: contentItem.Config.border.thickness * (1 - fsTransitionProg)
    readonly property real borderRounding: contentItem.Config.border.rounding * (1 - fsTransitionProg)
    readonly property real shadowOpacity: 0.7 * (1 - fsTransitionProg)
    readonly property real borderLayoutThickness: hasFullscreen ? 0 : contentItem.Config.border.thickness

    property color surfaceColour: Colours.tPalette.m3surface

    readonly property int dragMaskPadding: {
        if (focusGrabState.active || panels.popouts.isDetached)
            return 0;

        if (!monitor || monitor.lastIpcObject.specialWorkspace?.name || monitor.activeWorkspace.lastIpcObject.windows > 0)
            return 0;

        const thresholds = [];
        for (const panel of ["dashboard", "launcher", "session", "sidebar"])
            if (contentItem.Config[panel].enabled)
                thresholds.push(contentItem.Config[panel].dragThreshold);
        return Math.max(...thresholds);
    }

    onHasFullscreenChanged: {
        visibilities.launcher = false;
        visibilities.session = false;
        visibilities.dashboard = false;
        panels.popouts.close();
    }

    name: "drawers"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: (fsTransitionProg > 0 && contentItem.Config.general.showOverFullscreen) || (hasSpecialWorkspace && hasFullscreenOnNormalWs) ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: visibilities.launcher || visibilities.session || visibilities.dashboard || visibilities.sidebar || panels.popouts.hasCurrent ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: {
        if (hasFullscreen) return emptyRegion;
        if (focusGrabState.active || panels.popouts.isDetached) return fullRegion;
        return regions;
    }

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    Behavior on fsTransitionProg {
        Anim {}
    }

    Behavior on surfaceColour {
        CAnim {}
    }

    Region {
        id: emptyRegion

        x: panels.notifications.x + panels.leftMargin
        y: panels.notifications.y + panels.topMargin
        width: panels.notifications.width
        height: panels.notifications.height

        Region {
            x: root.width - width
            y: panels.osdWrapper.y + panels.topMargin
            width: panels.osdWrapper.width * (1 - panels.osd.offsetScale) + panels.topMargin
            height: panels.osd.height
        }
    }

    Regions {
        id: regions

        bar: bar
        panels: panels
        win: root
    }

    Region {
        id: fullRegion
        x: 0
        y: 0
        width: root.width
        height: root.height
    }



    QtObject {
        id: focusGrabState

        property bool active: (visibilities.launcher && root.contentItem.Config.launcher.enabled) || (visibilities.session && root.contentItem.Config.session.enabled) || (visibilities.sidebar && root.contentItem.Config.sidebar.enabled) || (!root.contentItem.Config.dashboard.showOnHover && visibilities.dashboard && root.contentItem.Config.dashboard.enabled) || (!root.contentItem.Config.utilities.showOnHover && visibilities.utilities && root.contentItem.Config.utilities.enabled) || (panels.popouts.currentName.startsWith("traymenu") && (panels.popouts.current as StackView)?.depth > 1)
        
        onActiveChanged: {
        }
        
        function clear() {
            visibilities.launcher = false;
            visibilities.session = false;
            visibilities.sidebar = false;
            visibilities.dashboard = false;
            visibilities.utilities = false;
            panels.popouts.hasCurrent = false;
            panels.popouts.detachedMode = "";
            bar.closeTray();
        }
    }

    StyledRect {
        anchors.fill: parent
        opacity: (visibilities.session && Config.session.enabled) || panels.popouts.detachedMode !== "" ? 0.5 : 0
        color: Colours.palette.m3scrim

        property bool _wasActive: false

        Timer {
            id: kdeFocusGrab
            interval: 100
            repeat: true
            running: focusGrabState.active || panels.popouts.isDetached
            onRunningChanged: {
                if (!running) {
                    parent._wasActive = false;
                }
            }
            onTriggered: {
                let anyActive = root.active || root.activeFocusItem !== null;
                
                if (anyActive) {
                    parent._wasActive = true;
                } else if (parent._wasActive && !anyActive) {
                    parent._wasActive = false;
                    focusGrabState.clear();
                    if (panels.popouts.isDetached) panels.popouts.close();
                }
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }

    Item {
        id: layoutContainer

        Config.screen: root.screen.name
        anchors.fill: parent
        opacity: GlobalConfig.appearance.pitchBlack ? 1 : (Colours.transparency.enabled ? Colours.transparency.base : 1.0)
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 15
            shadowColor: Qt.alpha(Colours.palette.m3shadow, Math.max(0, root.shadowOpacity))
        }

        BlobGroup {
            id: blobGroup

            color: GlobalConfig.appearance.pitchBlack ? "#000000" : root.surfaceColour
            smoothing: root.contentItem.Config.border.smoothing
        }

        BlobInvertedRect {
            Config.screen: root.screen.name
            anchors.fill: parent
            anchors.margins: -50 // Make border thicker to smooth out bulge from closed drawers
            group: GlobalConfig.appearance.islands ? null : blobGroup
            visible: !GlobalConfig.appearance.islands
            radius: root.borderRounding
            borderLeft: (Config.bar.position === "left" ? bar.implicitWidth : root.borderThickness) - anchors.margins - root.sdfBorderOffset
            borderRight: (Config.bar.position === "right" ? bar.implicitWidth : root.borderThickness) - anchors.margins - root.sdfBorderOffset
            borderTop: (Config.bar.position === "top" ? bar.implicitHeight : root.borderThickness) - anchors.margins - root.sdfBorderOffset
            borderBottom: (Config.bar.position === "bottom" ? bar.implicitHeight : root.borderThickness) - anchors.margins - root.sdfBorderOffset
        }

        BlobRect {
            visible: GlobalConfig.appearance.islands
            group: GlobalConfig.appearance.islands ? blobGroup : null
            x: bar.x
            y: bar.y
            implicitWidth: bar.width
            implicitHeight: bar.height
            radius: Tokens.rounding.extraLarge
            deformScale: (0.1 * Config.appearance.deformScale) / 10000
        }

        PanelBg {
            id: dashBg

            panel: panels.dashboard
            deformAmount: 0.1
        }

        PanelBg {
            id: launcherBg

            panel: panels.launcher
            deformAmount: 0.1
        }

        PanelBg {
            id: sessionBg

            panel: panels.sessionWrapper
            deformAmount: 0.2
            x: panels.sessionWrapper.x + panels.leftMargin
            implicitWidth: panels.sessionWrapper.width
        }

        PanelBg {
            id: sidebarBg

            panel: panels.sidebar
            deformAmount: 0.03
            implicitHeight: panel.height * (1 / rawDeformMatrix.m22) + 2
            
            property bool connectedToPopout: (Config.bar.position === "top" || Config.bar.position === "bottom") && panels.popouts.sidebarOpen && panels.popouts.implicitWidth <= Tokens.sizes.sidebar.width + 1 && !panels.popouts.isDockPopout
            
            exclude: {
                let arr = [];
                if (panels.sidebar.offsetScale <= 0.08) arr.push(utilsBg);
                if (connectedToPopout) arr.push(popoutBg);
                return arr;
            }
            
            topLeftRadius: GlobalConfig.appearance.islands ? radius : ((Config.bar.position === "top" && connectedToPopout) ? 0 : (Config.bar.position === "bottom" ? Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius : radius))
            topRightRadius: GlobalConfig.appearance.islands ? radius : ((Config.bar.position === "top" && connectedToPopout) ? 0 : (Config.bar.position === "bottom" ? Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius : radius))
            bottomLeftRadius: GlobalConfig.appearance.islands ? radius : ((Config.bar.position === "bottom" && connectedToPopout) ? 0 : (Config.bar.position === "right" ? radius : Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius))
            bottomRightRadius: GlobalConfig.appearance.islands ? radius : ((Config.bar.position === "bottom" && connectedToPopout) ? 0 : (Config.bar.position === "right" ? Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius : radius))
        }

        PanelBg {
            id: osdBg

            panel: panels.osdWrapper
            deformAmount: 0.25
            x: panels.osdWrapper.x + panels.leftMargin
            implicitWidth: panels.osdWrapper.width
        }

        PanelBg {
            id: notifsBg

            panel: panels.notifications
        }

        PanelBg {
            id: utilsBg

            panel: panels.utilities
            deformAmount: panels.sidebar.visible ? 0.1 : 0.15
            exclude: panels.sidebar.offsetScale > 0.08 ? [] : [sidebarBg]
            topLeftRadius: GlobalConfig.appearance.islands ? radius : (Config.bar.position === "right" ? radius : (Config.bar.position === "bottom" ? radius : Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius))
            topRightRadius: GlobalConfig.appearance.islands ? radius : (Config.bar.position === "right" ? Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius : (Config.bar.position === "bottom" ? radius : Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius))
            bottomLeftRadius: GlobalConfig.appearance.islands ? radius : (Config.bar.position === "bottom" ? Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius : radius)
            bottomRightRadius: GlobalConfig.appearance.islands ? radius : (Config.bar.position === "bottom" ? Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius : radius)
        }

        PanelBg {
            id: popoutBg

            // Extra width/height to prevent dynamic movement deformation partially detaching panel from bar
            property real extraShift: panels.popouts.isDetached ? 0 : 0.2
            property bool connectedToSidebar: (bar.position === "top" || bar.position === "bottom") && panels.popouts.sidebarOpen && panels.popouts.implicitWidth <= Tokens.sizes.sidebar.width + 1 && !panels.popouts.isDockPopout

            panel: panels.popoutsWrapper
            deformAmount: connectedToSidebar ? 0.03 : (panels.popouts.isDetached ? 0.05 : panels.popouts.hasCurrent ? 0.15 : 0.1)
            exclude: connectedToSidebar ? [sidebarBg] : []
            
            x: {
                const baseX = panels.popoutsWrapper.x + panels.popouts.x + panels.leftMargin;
                if (bar.position === "left")
                    return baseX - panels.popouts.implicitWidth * extraShift;
                return baseX;
            }
            implicitWidth: {
                if (bar.position === "left" || bar.position === "right")
                    return panels.popouts.implicitWidth * (1 + extraShift);
                return panels.popouts.implicitWidth;
            }
            
            bottomLeftRadius: GlobalConfig.appearance.islands ? radius : ((bar.position === "top" && connectedToSidebar) ? 0 : radius)
            bottomRightRadius: GlobalConfig.appearance.islands ? radius : ((bar.position === "top" && connectedToSidebar) ? 0 : radius)
            topLeftRadius: GlobalConfig.appearance.islands ? radius : ((bar.position === "bottom" && connectedToSidebar) ? 0 : radius)
            topRightRadius: GlobalConfig.appearance.islands ? radius : ((bar.position === "bottom" && connectedToSidebar) ? 0 : radius)

            y: {
                const baseY = panels.popoutsWrapper.y + panels.popouts.y + panels.topMargin;
                if (bar.position === "top")
                    return baseY - panels.popouts.implicitHeight * extraShift;
                if (bar.position === "bottom" && connectedToSidebar)
                    return baseY - Tokens.spacing.extraLarge - 10;
                return baseY;
            }
            implicitHeight: {
                if (bar.position === "top" || bar.position === "bottom") {
                    let h = panels.popouts.implicitHeight * (1 + extraShift);
                    if (connectedToSidebar) h += Tokens.spacing.extraLarge + 10;
                    return h;
                }
                return panels.popouts.implicitHeight;
            }

            Behavior on extraShift {
                Anim {
                    type: Anim.DefaultSpatial
                }
            }
        }
    }

    DrawerVisibilities {
        id: visibilities

        Component.onCompleted: Visibilities.load(root.screen, this)
    }

    Interactions {
        id: interactions

        screen: root.screen
        popouts: panels.popouts
        visibilities: visibilities
        panels: panels
        bar: bar
        borderThickness: root.borderLayoutThickness
        fullscreen: root.hasFullscreen
        focusGrab: focusGrabState

        states: [
            State {
                name: "left"
                Config.screen: root.screen.name
                when: Config.bar.position === "left"

                AnchorChanges {
                    target: bar
                    anchors.left: parent.left
                    anchors.right: undefined
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                }
                PropertyChanges {
                    target: bar
                    width: bar.implicitWidth
                    height: undefined
                    anchors.topMargin: GlobalConfig.appearance.islands ? Tokens.spacing.extraLarge : 0
                    anchors.bottomMargin: GlobalConfig.appearance.islands ? Tokens.spacing.extraLarge : 0
                    anchors.leftMargin: GlobalConfig.appearance.islands ? Tokens.spacing.extraLarge : 0
                    anchors.rightMargin: 0
                }
            },

            State {
                name: "right"
                Config.screen: root.screen.name
                when: Config.bar.position === "right"

                AnchorChanges {
                    target: bar
                    anchors.left: undefined
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                }
                PropertyChanges {
                    target: bar
                    width: bar.implicitWidth
                    height: undefined
                    anchors.topMargin: GlobalConfig.appearance.islands ? Tokens.spacing.extraLarge : 0
                    anchors.bottomMargin: GlobalConfig.appearance.islands ? Tokens.spacing.extraLarge : 0
                    anchors.leftMargin: 0
                    anchors.rightMargin: GlobalConfig.appearance.islands ? Tokens.spacing.extraLarge : 0
                }
            },

            State {
                name: "top"
                Config.screen: root.screen.name
                when: Config.bar.position === "top"

                AnchorChanges {
                    target: bar
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: undefined
                }
                PropertyChanges {
                    target: bar
                    width: undefined
                    height: bar.implicitHeight
                    anchors.leftMargin: GlobalConfig.appearance.islands ? Tokens.spacing.extraLarge : 0
                    anchors.rightMargin: GlobalConfig.appearance.islands ? Tokens.spacing.extraLarge : 0
                    anchors.topMargin: GlobalConfig.appearance.islands ? Tokens.spacing.extraLarge : 0
                    anchors.bottomMargin: 0
                }
            },

            State {
                name: "bottom"
                Config.screen: root.screen.name
                when: Config.bar.position === "bottom"

                AnchorChanges {
                    target: bar
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: undefined
                    anchors.bottom: parent.bottom
                }
                PropertyChanges {
                    target: bar
                    width: undefined
                    height: bar.implicitHeight
                    anchors.leftMargin: GlobalConfig.appearance.islands ? Tokens.spacing.extraLarge : 0
                    anchors.rightMargin: GlobalConfig.appearance.islands ? Tokens.spacing.extraLarge : 0
                    anchors.bottomMargin: GlobalConfig.appearance.islands ? Tokens.spacing.extraLarge : 0
                    anchors.topMargin: 0
                }
            }
        ]

        Panels {
            id: panels

            screen: root.screen
            visibilities: visibilities
            bar: bar
            borderThickness: root.borderThickness

            utilities.horizontalStretch: (sidebarBg.rawDeformMatrix.m11 - 1) / 2 + 1
            utilities.deformMatrix: utilsBg.rawDeformMatrix

            dashboard.transform: Matrix4x4 {
                matrix: dashBg.deformMatrix
            }
            launcher.transform: Matrix4x4 {
                matrix: launcherBg.deformMatrix
            }
            session.transform: Matrix4x4 {
                matrix: sessionBg.deformMatrix
            }
            sidebar.transform: Matrix4x4 {
                matrix: sidebarBg.deformMatrix
            }
            osd.transform: Matrix4x4 {
                matrix: osdBg.deformMatrix
            }
            notifications.transform: Matrix4x4 {
                matrix: notifsBg.deformMatrix
            }
            utilities.transform: Matrix4x4 {
                matrix: utilsBg.deformMatrix
            }
            popouts.transform: Matrix4x4 {
                matrix: popoutBg.deformMatrix
            }
        }

        BarWrapper {
            id: bar

            screen: root.screen
            visibilities: visibilities
            popouts: panels.popouts

            fullscreen: root.hasFullscreen

            Component.onCompleted: Visibilities.registerBar(root.screen, this)
        }
    }

    component PanelBg: BlobRect {
        required property Item panel
        property real deformAmount: 0.15
        Config.screen: root.screen.name

        group: panel.visible ? blobGroup : null
        x: panel.x + panels.leftMargin
        y: panel.y + panels.topMargin
        implicitWidth: panel.width
        implicitHeight: panel.height
        radius: Tokens.rounding.extraLarge
        deformScale: (deformAmount * Config.appearance.deformScale) / 10000
    }
}
