import QtQuick
import Quickshell

Region {
    required property string vAnchor
    required property real inLeft
    required property real inRight
    required property real inTop
    required property real inBottom
    required property real rTop
    required property real rBottom
    required property real rLeft
    required property real rRight

    property real rVert: vAnchor === "top" ? rBottom : rTop
    property real rL: Math.min(rVert, rLeft)
    property real rR: Math.min(rVert, rRight)
    property real baseYL: vAnchor === "top" ? inBottom : inTop
    property real baseYR: vAnchor === "top" ? inBottom : inTop
    // Left Corner (dynamically Top-Left or Bottom-Left depending on vAnchor)
    // Note: Quickshell Region strictly expects PendingRegion objects.
    // QML Repeater cannot be used here because it evaluates to a QQuickRepeater object.
    // Thus, this loop is mathematically unrolled.
    Region { x: inLeft - rL*0.9987 + 1; y: vAnchor === "top" ? inBottom : inTop - rL*0.0500; width: rL*0.9987; height: rL*0.0500 }
    Region { x: inLeft - rL*0.9950 + 1; y: vAnchor === "top" ? inBottom : inTop - rL*0.1000; width: rL*0.9950; height: rL*0.1000 }
    Region { x: inLeft - rL*0.9887 + 1; y: vAnchor === "top" ? inBottom : inTop - rL*0.1500; width: rL*0.9887; height: rL*0.1500 }
    Region { x: inLeft - rL*0.9798 + 1; y: vAnchor === "top" ? inBottom : inTop - rL*0.2000; width: rL*0.9798; height: rL*0.2000 }
    Region { x: inLeft - rL*0.9682 + 1; y: vAnchor === "top" ? inBottom : inTop - rL*0.2500; width: rL*0.9682; height: rL*0.2500 }
    Region { x: inLeft - rL*0.9539 + 1; y: vAnchor === "top" ? inBottom : inTop - rL*0.3000; width: rL*0.9539; height: rL*0.3000 }
    Region { x: inLeft - rL*0.9367 + 1; y: vAnchor === "top" ? inBottom : inTop - rL*0.3500; width: rL*0.9367; height: rL*0.3500 }
    Region { x: inLeft - rL*0.9165 + 1; y: vAnchor === "top" ? inBottom : inTop - rL*0.4000; width: rL*0.9165; height: rL*0.4000 }
    Region { x: inLeft - rL*0.8930 + 1; y: vAnchor === "top" ? inBottom : inTop - rL*0.4500; width: rL*0.8930; height: rL*0.4500 }
    Region { x: inLeft - rL*0.8660 + 1; y: vAnchor === "top" ? inBottom : inTop - rL*0.5000; width: rL*0.8660; height: rL*0.5000 }
    Region { x: inLeft - rL*0.8352 + 1; y: vAnchor === "top" ? inBottom : inTop - rL*0.5500; width: rL*0.8352; height: rL*0.5500 }
    Region { x: inLeft - rL*0.8000 + 1; y: vAnchor === "top" ? inBottom : inTop - rL*0.6000; width: rL*0.8000; height: rL*0.6000 }
    Region { x: inLeft - rL*0.7599 + 1; y: vAnchor === "top" ? inBottom : inTop - rL*0.6500; width: rL*0.7599; height: rL*0.6500 }
    Region { x: inLeft - rL*0.7141 + 1; y: vAnchor === "top" ? inBottom : inTop - rL*0.7000; width: rL*0.7141; height: rL*0.7000 }
    Region { x: inLeft - rL*0.6614 + 1; y: vAnchor === "top" ? inBottom : inTop - rL*0.7500; width: rL*0.6614; height: rL*0.7500 }
    Region { x: inLeft - rL*0.6000 + 1; y: vAnchor === "top" ? inBottom : inTop - rL*0.8000; width: rL*0.6000; height: rL*0.8000 }
    Region { x: inLeft - rL*0.5268 + 1; y: vAnchor === "top" ? inBottom : inTop - rL*0.8500; width: rL*0.5268; height: rL*0.8500 }
    Region { x: inLeft - rL*0.4359 + 1; y: vAnchor === "top" ? inBottom : inTop - rL*0.9000; width: rL*0.4359; height: rL*0.9000 }
    Region { x: inLeft - rL*0.3122 + 1; y: vAnchor === "top" ? inBottom : inTop - rL*0.9500; width: rL*0.3122; height: rL*0.9500 }

    // Right Corner (dynamically Top-Right or Bottom-Right depending on vAnchor)
    Region { x: inRight; y: vAnchor === "top" ? inBottom : inTop - rR*0.0500; width: rR*0.9987; height: rR*0.0500 }
    Region { x: inRight; y: vAnchor === "top" ? inBottom : inTop - rR*0.1000; width: rR*0.9950; height: rR*0.1000 }
    Region { x: inRight; y: vAnchor === "top" ? inBottom : inTop - rR*0.1500; width: rR*0.9887; height: rR*0.1500 }
    Region { x: inRight; y: vAnchor === "top" ? inBottom : inTop - rR*0.2000; width: rR*0.9798; height: rR*0.2000 }
    Region { x: inRight; y: vAnchor === "top" ? inBottom : inTop - rR*0.2500; width: rR*0.9682; height: rR*0.2500 }
    Region { x: inRight; y: vAnchor === "top" ? inBottom : inTop - rR*0.3000; width: rR*0.9539; height: rR*0.3000 }
    Region { x: inRight; y: vAnchor === "top" ? inBottom : inTop - rR*0.3500; width: rR*0.9367; height: rR*0.3500 }
    Region { x: inRight; y: vAnchor === "top" ? inBottom : inTop - rR*0.4000; width: rR*0.9165; height: rR*0.4000 }
    Region { x: inRight; y: vAnchor === "top" ? inBottom : inTop - rR*0.4500; width: rR*0.8930; height: rR*0.4500 }
    Region { x: inRight; y: vAnchor === "top" ? inBottom : inTop - rR*0.5000; width: rR*0.8660; height: rR*0.5000 }
    Region { x: inRight; y: vAnchor === "top" ? inBottom : inTop - rR*0.5500; width: rR*0.8352; height: rR*0.5500 }
    Region { x: inRight; y: vAnchor === "top" ? inBottom : inTop - rR*0.6000; width: rR*0.8000; height: rR*0.6000 }
    Region { x: inRight; y: vAnchor === "top" ? inBottom : inTop - rR*0.6500; width: rR*0.7599; height: rR*0.6500 }
    Region { x: inRight; y: vAnchor === "top" ? inBottom : inTop - rR*0.7000; width: rR*0.7141; height: rR*0.7000 }
    Region { x: inRight; y: vAnchor === "top" ? inBottom : inTop - rR*0.7500; width: rR*0.6614; height: rR*0.7500 }
    Region { x: inRight; y: vAnchor === "top" ? inBottom : inTop - rR*0.8000; width: rR*0.6000; height: rR*0.8000 }
    Region { x: inRight; y: vAnchor === "top" ? inBottom : inTop - rR*0.8500; width: rR*0.5268; height: rR*0.8500 }
    Region { x: inRight; y: vAnchor === "top" ? inBottom : inTop - rR*0.9000; width: rR*0.4359; height: rR*0.9000 }
    Region { x: inRight; y: vAnchor === "top" ? inBottom : inTop - rR*0.9500; width: rR*0.3122; height: rR*0.9500 }
}
