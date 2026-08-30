pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    isSubPage: true
    title: qsTr("Lock Screen")

    readonly property list<MenuItem> fprintTriesItems: [
        MenuItem {
            property int value: 1

            text: qsTr("1 attempt")
        },
        MenuItem {
            property int value: 2

            text: qsTr("2 attempts")
        },
        MenuItem {
            property int value: 3

            text: qsTr("3 attempts")
        },
        MenuItem {
            property int value: 4

            text: qsTr("4 attempts")
        },
        MenuItem {
            property int value: 5

            text: qsTr("5 attempts")
        }
    ]

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Wallpaper
        SectionHeader {
            first: true
            text: qsTr("Wallpaper")
        }

        ToggleRow {
            first: true
            last: true
            Layout.fillWidth: true
            text: qsTr("Sync with desktop wallpaper")
            subtext: qsTr("Keep the lock screen wallpaper in sync with the desktop wallpaper")
            checked: Config.lock.syncWallpaper
            onToggled: {
                GlobalConfig.lock.syncWallpaper = checked;
                GlobalConfig.save();
                if (checked && Wallpapers.current && !Images.isVideo(Wallpapers.current))
                    Wallpapers.syncPlasmaWallpaper(Wallpapers.current);
            }
        }

        // Authentication
        SectionHeader {
            text: qsTr("Authentication")
        }

        ToggleRow {
            first: true
            Layout.fillWidth: true
            text: qsTr("Fingerprint unlock")
            subtext: qsTr("Allow fingerprint authentication on the lock screen")
            checked: Config.lock.enableFprint
            onToggled: {
                GlobalConfig.lock.enableFprint = checked;
                GlobalConfig.save();
            }
        }

        SelectRow {
            last: true
            Layout.fillWidth: true
            label: qsTr("Fingerprint attempts")
            subtext: qsTr("Tries before falling back to password")
            active: {
                for (let i = 0; i < fprintTriesItems.length; i++) {
                    if (fprintTriesItems[i].value === Config.lock.maxFprintTries)
                        return fprintTriesItems[i];
                }
                return fprintTriesItems[2];
            }
            menuItems: fprintTriesItems
            onSelected: item => {
                GlobalConfig.lock.maxFprintTries = item.value;
                GlobalConfig.save();
            }
        }

        // General
        SectionHeader {
            text: qsTr("General")
        }

        ToggleRow {
            first: true
            Layout.fillWidth: true
            text: qsTr("Lock on startup")
            subtext: qsTr("Lock the session shortly after logging in")
            checked: Config.lock.lockOnStartup
            onToggled: {
                GlobalConfig.lock.lockOnStartup = checked;
                GlobalConfig.save();
            }
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Hide notifications")
            subtext: qsTr("Hide notification previews until you unlock")
            checked: Config.lock.hideNotifs
            onToggled: {
                GlobalConfig.lock.hideNotifs = checked;
                GlobalConfig.save();
            }
        }

        ToggleRow {
            last: true
            Layout.fillWidth: true
            text: qsTr("Recolor logo")
            subtext: qsTr("Tint the lock screen artwork to match the palette")
            checked: Config.lock.recolourLogo
            onToggled: {
                GlobalConfig.lock.recolourLogo = checked;
                GlobalConfig.save();
            }
        }
    }
}
