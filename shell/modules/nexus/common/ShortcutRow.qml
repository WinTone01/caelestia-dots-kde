pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

ConnectedRect {
    id: root

    property alias label: label.text
    property alias status: status.text
    property string keybind: ""
    property bool isOverridden: false

    signal clicked
    signal resetClicked

    Layout.fillWidth: true
    implicitHeight: navLayout.implicitHeight + navLayout.anchors.margins * 2

    StateLayer {
        onClicked: root.clicked()
    }

    RowLayout {
        id: navLayout

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: label
                Layout.fillWidth: true
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            StyledText {
                id: status
                Layout.fillWidth: true
                visible: text
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
                animate: true
            }
        }

        RowLayout {
            spacing: Tokens.spacing.small

            Rectangle {
                Layout.preferredHeight: 32
                Layout.preferredWidth: Math.max(48, keybindText.implicitWidth + Tokens.padding.medium * 2)
                radius: Tokens.radius.small
                color: Colours.palette.m3surfaceContainerHigh
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                StyledText {
                    id: keybindText
                    anchors.centerIn: parent
                    text: root.keybind === "" ? qsTr("Unbound") : root.keybind
                    font: Tokens.font.label.medium
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
            
            MaterialIcon {
                visible: root.isOverridden
                text: "settings_backup_restore"
                color: maReset.containsMouse ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                
                MouseArea {
                    id: maReset
                    anchors.fill: parent
                    anchors.margins: -Tokens.padding.small
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.resetClicked()
                }
            }
        }
    }
}
