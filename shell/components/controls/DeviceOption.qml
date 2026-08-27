pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Compact single-line selectable row used for device pickers (e.g. audio
// output/input) in bar popouts. Explicit Layout.preferredWidth: 0 keeps long
// labels from inflating the popout's width - only elide handles overflow.
StyledRect {
    id: root

    property alias label: label.text
    property bool active

    signal selected

    Layout.fillWidth: true
    Layout.preferredWidth: 0
    implicitHeight: layout.implicitHeight + Tokens.padding.small * 2
    radius: Tokens.rounding.small
    color: active ? Colours.tPalette.m3surfaceContainerHigh : "transparent"

    RowLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: root.active ? "radio_button_checked" : "radio_button_unchecked"
            color: root.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.small
        }

        StyledText {
            id: label

            Layout.fillWidth: true
            Layout.preferredWidth: 0
            elide: Text.ElideRight
            color: root.active ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
        }
    }

    StateLayer {
        anchors.fill: parent
        radius: root.radius
        onClicked: root.selected()
    }
}
