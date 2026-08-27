pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("App volumes")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.medium
            text: qsTr("Adjust the volume of individual apps currently playing audio.")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        ItemList {
            id: streamList

            first: true
            last: true
            showList: true
            placeholderIcon: "music_off"
            placeholderText: qsTr("No apps playing audio")
            color: list.count === 0 ? Colours.tPalette.m3surfaceContainer : "transparent"
            list.spacing: Tokens.spacing.extraSmall / 2

            model: ScriptModel {
                values: [...Audio.appStreams]
            }

            delegate: SliderRow {
                id: stream

                required property PwNode modelData
                required property int index

                anchors.left: streamList.list.contentItem.left
                anchors.right: streamList.list.contentItem.right
                first: index === 0
                last: index === streamList.list.count - 1

                icon: Icons.getVolumeIcon(Audio.getAppVolume(stream.modelData), Audio.getAppMuted(stream.modelData))
                label: Audio.getStreamName(stream.modelData)
                valueLabel: Audio.getAppMuted(stream.modelData) ? qsTr("Muted") : Math.round(value * 100) + "%"
                value: Audio.getAppVolume(stream.modelData)
                enabled: !Audio.getAppMuted(stream.modelData)
                onMoved: v => Audio.setAppVolume(stream.modelData, v)
            }
        }
    }
}
