pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Compact label + value + slider row. This is the shared, stripped-down
// equivalent of modules/nexus/common/SliderRow.qml, moved into the generic
// components namespace so bar popouts can use it without creating a reverse
// bar -> nexus dependency.
StyledRect {
    id: root

    property alias icon: icon.text
    property alias label: label.text
    property alias valueLabel: valueLabel.text
    property string subtext
    property real value
    property bool first
    property bool last

    signal moved(value: real)
    signal interaction(value: real)
    signal released(value: real)

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins + rowLayout.anchors.topMargin
    color: Colours.tPalette.m3surfaceContainer
    topLeftRadius: first ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    topRightRadius: first ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    bottomLeftRadius: last ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    bottomRightRadius: last ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall

    RowLayout {
        id: rowLayout

        anchors.fill: parent
        anchors.margins: Tokens.padding.largeIncreased
        anchors.topMargin: Tokens.padding.large
        spacing: Tokens.spacing.medium

        MaterialIcon {
            id: icon

            visible: text !== ""
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

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
                        Layout.fillWidth: true
                        visible: root.subtext !== ""
                        text: root.subtext
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                StyledText {
                    id: valueLabel

                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }
            }

            CustomMouseArea {
                function onWheel(event: WheelEvent): void {
                    const step = GlobalConfig.services.audioIncrement;
                    if (event.angleDelta.y > 0)
                        root.moved(Math.min(1, root.value + step));
                    else if (event.angleDelta.y < 0)
                        root.moved(Math.max(0, root.value - step));
                }

                Layout.fillWidth: true
                implicitHeight: Tokens.padding.medium * 2

                StyledSlider {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    implicitHeight: parent.implicitHeight

                    radius: Tokens.rounding.small
                    value: root.value
                    enabled: root.enabled
                    onInteraction: v => {
                        root.moved(v);
                        root.interaction(v);
                    }
                    onReleased: v => root.released(v)
                }
            }
        }
    }
}
