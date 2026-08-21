pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.services

Item {
    id: root

    required property var client

    implicitWidth: 400
    implicitHeight: 300

    Item {
        id: previewContainer

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Tokens.padding.large
        anchors.bottomMargin: Tokens.spacing.medium

        StyledClippingRect {
            id: preview

            readonly property real windowAspect: {
                const w = root.client ? (root.client.width > 0 ? root.client.width : 16) : 16;
                const h = root.client ? (root.client.height > 0 ? root.client.height : 10) : 10;
                return w / h;
            }

            width: {
                const containerAspect = previewContainer.width / previewContainer.height;
                if (windowAspect > containerAspect) {
                    return previewContainer.width;
                } else {
                    return previewContainer.height * windowAspect;
                }
            }
            height: {
                const containerAspect = previewContainer.width / previewContainer.height;
                if (windowAspect > containerAspect) {
                    return previewContainer.width / windowAspect;
                } else {
                    return previewContainer.height;
                }
            }
            anchors.centerIn: parent
            radius: Tokens.rounding.medium

                Loader {
                    asynchronous: true
                    anchors.centerIn: parent
                    active: !root.client
                    sourceComponent: ColumnLayout {
                        spacing: 0

                        MaterialIcon {
                            text: "web_asset_off"
                            color: Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.builders.extraLarge.scale(3).build()
                            Layout.alignment: Qt.AlignHCenter
                        }
                        StyledText {
                            text: qsTr("No active client")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.builders.large.size(28).weight(Font.Medium).build()
                            Layout.alignment: Qt.AlignHCenter
                        }
                        StyledText {
                            text: qsTr("Try switching to a window")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.large
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
                // Live capture is gone with the screencast protocol; a window that
                // exists still deserves to be identified, so stand its icon in for
                // the missing frames rather than showing the empty-state text, which
                // would claim there is no client at all.
                IconImage {
                    anchors.centerIn: parent
                    implicitSize: Math.min(preview.width, preview.height) * 0.4
                    asynchronous: true
                    visible: !!root.client
                    source: root.client ? WinIcons.sourceFor(null, root.client.class, root.client.iconName, root.client.pid ?? 0) : ""
                }
    }
}
    Layout.fillWidth: true
    Layout.fillHeight: true
}
