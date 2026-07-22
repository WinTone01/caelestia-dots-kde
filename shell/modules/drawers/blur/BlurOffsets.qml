import QtQuick
import Caelestia.Config

QtObject {
    id: root

    required property Item target
    property string vAnchor: "bottom" 
    property string hAnchor: "right"
    property real offsetScale: 0
    
    required property Item contentItem
    
    property real blurOffsetTop: 0
    property real blurOffsetBottom: 0
    property real blurOffsetLeft: 0
    property real blurOffsetRight: 0

    property bool isActive: target && target.visible && target.opacity > 0 && GlobalConfig.appearance.transparency.enabled && GlobalConfig.appearance.blur
    
    property real animScale: 1 - offsetScale
    
    property real sTop: (vAnchor === "top" ? blurOffsetBottom : blurOffsetTop) * animScale
    property real sBottom: (vAnchor === "top" ? blurOffsetTop : blurOffsetBottom) * animScale
    property real sLeft: (hAnchor === "left" ? blurOffsetRight : blurOffsetLeft) * animScale
    property real sRight: (hAnchor === "left" ? blurOffsetLeft : blurOffsetRight) * animScale
    
    property real tX: {
        if (!target) return 0;
        let _ = target.x + target.width; // Dependency tracking
        return target.parent ? target.parent.mapToItem(contentItem, target.x, target.y).x : 0;
    }
    property real tY: {
        if (!target) return 0;
        let _ = target.y + target.height; // Dependency tracking
        return target.parent ? target.parent.mapToItem(contentItem, target.x, target.y).y : 0;
    }
    
    property real bX: tX + sLeft
    property real bY: tY + sTop
    property real bW: isActive ? Math.max(0, (target ? target.width : 0) - sLeft - sRight) : 0
    property real bH: isActive ? Math.max(0, (target ? target.height : 0) - sTop - sBottom) : 0
    
    property real r: isActive ? Tokens.rounding.extraLarge * animScale : 0
    property bool isIsland: GlobalConfig.appearance.islands
    
    property real rTop: (!isIsland && vAnchor === "top") ? 0 : r
    property real rBottom: (!isIsland && vAnchor === "bottom") ? 0 : r
    property real rLeft: r
    property real rRight: r
    
    property real inLeft: bX + rLeft
    property real inRight: bX + bW - rRight
    property real inTop: bY + rTop
    property real inBottom: bY + bH - rBottom
}
