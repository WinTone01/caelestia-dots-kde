import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls as Controls
import qs.components.effects

Popup {
    id: root

    property string shortcutName: ""
    property string currentKey: ""
    property string capturedKey: ""

    signal confirm(string name, string newKey)
    signal clear(string name)

    width: 320
    padding: 24
    height: contentColumn.implicitHeight + 48
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)

    background: Item {
        Elevation {
            anchors.fill: bgRect
            level: 3
            radius: bgRect.radius
        }
        Rectangle {
            id: bgRect
            anchors.fill: parent
            color: Colours.palette.surface
            radius: 16
            border.width: 1
            border.color: Colours.palette.surfaceVariant
        }
    }

    onOpened: {
        capturedKey = currentKey
        focusScope.forceActiveFocus()
    }

    contentItem: ColumnLayout {
        id: contentColumn
        spacing: 16

        StyledText {
            text: qsTr("Record Keybind")
            font: Tokens.font.title.medium
            color: Colours.palette.onSurface
            Layout.fillWidth: true
        }

        FocusScope {
            id: focusScope
            Layout.fillWidth: true
            Layout.preferredHeight: 64

            Rectangle {
                anchors.fill: parent
                color: focusScope.activeFocus ? Colours.palette.primaryContainer : Colours.palette.surfaceVariant
                radius: Tokens.radius.medium
                border.width: focusScope.activeFocus ? 2 : 1
                border.color: focusScope.activeFocus ? Colours.palette.primary : Colours.palette.outline

                StyledText {
                    anchors.centerIn: parent
                    text: root.capturedKey === "" ? qsTr("Press keys now...") : root.capturedKey
                    font: Tokens.font.body.large
                    color: focusScope.activeFocus ? Colours.palette.onPrimaryContainer : Colours.palette.onSurfaceVariant
                }
            }

            Keys.onPressed: (event) => {
                let modifiers = ""
                if (event.modifiers & Qt.MetaModifier) modifiers += "Meta+"
                if (event.modifiers & Qt.ControlModifier) modifiers += "Ctrl+"
                if (event.modifiers & Qt.AltModifier) modifiers += "Alt+"
                if (event.modifiers & Qt.ShiftModifier) modifiers += "Shift+"

                let keyStr = ""
                // Ignore bare modifiers
                if (event.key !== Qt.Key_Meta && event.key !== Qt.Key_Control && 
                    event.key !== Qt.Key_Alt && event.key !== Qt.Key_Shift && 
                    event.key !== Qt.Key_Super_L && event.key !== Qt.Key_Super_R) {
                    
                    if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z) {
                        keyStr = String.fromCharCode(event.key)
                    } else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                        keyStr = String.fromCharCode(event.key)
                    } else if (event.key === Qt.Key_Space) {
                        keyStr = "Space"
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        keyStr = "Return"
                    } else if (event.key === Qt.Key_Escape) {
                        keyStr = "Escape"
                    } else if (event.key === Qt.Key_Tab) {
                        keyStr = "Tab"
                    } else if (event.key === Qt.Key_Up) {
                        keyStr = "Up"
                    } else if (event.key === Qt.Key_Down) {
                        keyStr = "Down"
                    } else if (event.key === Qt.Key_Left) {
                        keyStr = "Left"
                    } else if (event.key === Qt.Key_Right) {
                        keyStr = "Right"
                    } else {
                        // Fallback (e.g. F-keys)
                        // Note: QKeySequence string conversion isn't directly exposed to JS, 
                        // so we handle common ones. Others might be obscure.
                        keyStr = String.fromCharCode(event.key)
                    }
                    root.capturedKey = modifiers + keyStr
                }
                event.accepted = true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            
            Controls.TextButton {
                text: qsTr("Clear")
                onClicked: {
                    root.clear(root.shortcutName)
                    root.close()
                }
            }

            Item { Layout.fillWidth: true }

            Controls.TextButton {
                text: qsTr("Cancel")
                onClicked: root.close()
            }

            Controls.TextButton {
                text: qsTr("Confirm")
                onClicked: {
                    root.confirm(root.shortcutName, root.capturedKey)
                    root.close()
                }
            }
        }
    }
}
