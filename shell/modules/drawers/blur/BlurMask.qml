import QtQuick
import Quickshell

Region {
    id: root
    required property Item target
    required property Item contentItem
    property string vAnchor: "bottom" 
    property string hAnchor: "right"
    property real offsetScale: 0
    
    property real blurOffsetTop: 0
    property real blurOffsetBottom: 0
    property real blurOffsetLeft: 0
    property real blurOffsetRight: 0

    property BlurOffsets offsets: BlurOffsets {
        target: root.target
        contentItem: root.contentItem
        vAnchor: root.vAnchor
        hAnchor: root.hAnchor
        offsetScale: root.offsetScale
        blurOffsetTop: root.blurOffsetTop
        blurOffsetBottom: root.blurOffsetBottom
        blurOffsetLeft: root.blurOffsetLeft
        blurOffsetRight: root.blurOffsetRight
    }

    BlurBodies {
        bX: root.offsets.bX
        bY: root.offsets.bY
        bW: root.offsets.bW
        bH: root.offsets.bH
        inLeft: root.offsets.inLeft
        inRight: root.offsets.inRight
        inTop: root.offsets.inTop
        inBottom: root.offsets.inBottom
    }

    BlurCorners {
        inLeft: root.offsets.inLeft
        inRight: root.offsets.inRight
        inTop: root.offsets.inTop
        inBottom: root.offsets.inBottom
        rTop: root.offsets.rTop
        rBottom: root.offsets.rBottom
    }
}
