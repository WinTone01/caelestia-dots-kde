pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property PopoutState popouts

    property bool _isSidebarOpen: popouts.sidebarOpen && popouts.isHorizontal

    readonly property real masterScale: !isNaN(GlobalConfig.bar.previewScale) ? GlobalConfig.bar.previewScale : 1.0
    readonly property real elementOffset: GlobalConfig.bar.perElementPreviewScale ? (!isNaN(GlobalConfig.bar.previewScales.audio) ? GlobalConfig.bar.previewScales.audio : 0.0) : 0.0
    readonly property real barScaleOffset: GlobalConfig.bar.previewScaleWithBar ? (!isNaN(GlobalConfig.bar.scale) ? GlobalConfig.bar.scale : 1.0) : 1.0
    readonly property real scaleOffset: Math.max(0.1, (masterScale + elementOffset) * barScaleOffset)
    readonly property real elementFontOffset: GlobalConfig.bar.perElementFontScale ? (!isNaN(GlobalConfig.bar.previewFontScales.audio) ? GlobalConfig.bar.previewFontScales.audio : 0.0) : 0.0
    readonly property real fontScale: Math.max(0.1, scaleOffset + (!isNaN(GlobalConfig.bar.fontScaleOffset) ? GlobalConfig.bar.fontScaleOffset : 0.0) + elementFontOffset)

    implicitWidth: Math.max(300 * scaleOffset, _isSidebarOpen ? (Tokens.sizes.sidebar.width * scaleOffset) - Tokens.padding.extraLargeIncreased : 0)
    spacing: Tokens.spacing.small * scaleOffset

    StyledText {
        Layout.topMargin: Tokens.padding.small * root.scaleOffset
        Layout.leftMargin: Tokens.padding.small * root.scaleOffset
        text: qsTr("Audio")
        font.weight: 500
        font.pointSize: Tokens.font.body.medium.pointSize * root.fontScale
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: devicesLayout.implicitHeight + Tokens.padding.small * 2 * root.scaleOffset
        radius: Tokens.rounding.medium * root.scaleOffset
        color: Colours.tPalette.m3surfaceContainer
        clip: true

        ColumnLayout {
            id: devicesLayout

            width: parent.width - Tokens.padding.small * 2 * root.scaleOffset
            x: Tokens.padding.small * root.scaleOffset
            y: Tokens.padding.small * root.scaleOffset
            spacing: Tokens.spacing.extraSmall * root.scaleOffset

            StyledText {
                text: qsTr("Output device")
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.label.small.pointSize * root.fontScale
            }

            Repeater {
                model: Audio.sinks

                DeviceOption {
                    required property PwNode modelData

                    label: modelData.description
                    active: Audio.sink?.id === modelData.id
                    onSelected: Audio.setAudioSink(modelData)
                }
            }

            StyledText {
                Layout.topMargin: Tokens.padding.extraSmall * root.scaleOffset
                text: qsTr("Input device")
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.label.small.pointSize * root.fontScale
            }

            Repeater {
                model: Audio.sources

                DeviceOption {
                    required property PwNode modelData

                    label: modelData.description
                    active: Audio.source?.id === modelData.id
                    onSelected: Audio.setAudioSource(modelData)
                }
            }
        }
    }

    StyledText {
        Layout.topMargin: Tokens.spacing.small * root.scaleOffset
        Layout.leftMargin: Tokens.padding.small * root.scaleOffset
        text: qsTr("Volume")
        font.weight: Font.Medium
        font.pointSize: Tokens.font.body.medium.pointSize * root.fontScale
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: volumeLayout.implicitHeight + Tokens.padding.small * 2 * root.scaleOffset
        radius: Tokens.rounding.medium * root.scaleOffset
        color: Colours.tPalette.m3surfaceContainer
        clip: true

        ColumnLayout {
            id: volumeLayout

            width: parent.width - Tokens.padding.small * 2 * root.scaleOffset
            x: Tokens.padding.small * root.scaleOffset
            y: Tokens.padding.small * root.scaleOffset
            spacing: Tokens.spacing.extraSmall / 2 * root.scaleOffset

            SliderRow {
                Layout.fillWidth: true
                first: true
                last: Audio.streams.length === 0
                iconClickable: true
                icon: Icons.getVolumeIcon(Audio.volume, Audio.muted)
                label: qsTr("Volume")
                valueLabel: Audio.muted ? qsTr("Muted") : Math.round(Audio.volume * 100) + "%"
                value: Audio.volume
                onIconClicked: {
                    if (Audio.sink?.ready && Audio.sink?.audio)
                        Audio.sink.audio.muted = !Audio.sink.audio.muted;
                }
                onMoved: v => Audio.setVolume(v)
                onReleased: v => Audio.playEffectTick()
            }

            Repeater {
                model: Audio.streams

                SliderRow {
                    required property PwNode modelData
                    required property int index

                    last: index === Audio.streams.length - 1
                    icon: Icons.getVolumeIcon(modelData?.audio?.volume ?? 0, modelData?.audio?.muted ?? false)
                    label: Audio.getStreamName(modelData)
                    valueLabel: Math.round(value * 100) + "%"
                    value: modelData?.audio?.volume ?? 0
                    enabled: !modelData?.audio?.muted
                    onMoved: v => Audio.setStreamVolume(modelData, v)
                }
            }
        }
    }

    IconTextButton {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.small * root.scaleOffset
        inactiveColour: Colours.palette.m3primaryContainer
        inactiveOnColour: Colours.palette.m3onPrimaryContainer
        verticalPadding: Tokens.padding.small * root.scaleOffset
        text: qsTr("Open settings")
        icon: "settings"

        onClicked: root.popouts.detachRequested("audio")
    }
}

