pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils

Column {
    id: root

    required property DrawerVisibilities visibilities

    padding: Tokens.padding.large
    rightPadding: CUtils.clamp(padding - Config.border.thickness, 0, padding)
    spacing: Tokens.spacing.large

    property var activeEntries: SessionStore.entries.filter(e => e.enabled)

    Repeater {
        id: repeater
        model: root.activeEntries

        delegate: Loader {
            id: loader
            property string compId: modelData.id
            property int itemIndex: index
            
            visible: true
            
            sourceComponent: {
                if (compId === "dino_gif") return dinoComponent;
                return buttonComponent;
            }

            // Connection to focus the first button on launcher change
            Connections {
                target: root.visibilities
                function onLauncherChanged() {
                    if (!root.visibilities.launcher && loader.item && typeof loader.item.forceActiveFocus === 'function' && index === root.firstFocusableIndex()) {
                        loader.item.forceActiveFocus();
                    }
                }
            }
            
            Component.onCompleted: {
                if (index === root.firstFocusableIndex() && loader.item && typeof loader.item.forceActiveFocus === 'function') {
                    loader.item.forceActiveFocus();
                }
            }
        }
    }

    function firstFocusableIndex() {
        for (let i = 0; i < root.activeEntries.length; i++) {
            if (root.activeEntries[i].id !== "dino_gif") return i;
        }
        return 0;
    }

    function findFocusable(startIndex, direction) {
        let i = startIndex + direction;
        while (i >= 0 && i < root.activeEntries.length) {
            if (root.activeEntries[i].id !== "dino_gif") {
                let loader = repeater.itemAt(i);
                if (loader && loader.item) return loader.item;
            }
            i += direction;
        }
        return null;
    }

    Component {
        id: dinoComponent
        Item {
            width: Tokens.sizes.session.button
            height: Tokens.sizes.session.button

            AnimatedImage {
                anchors.fill: parent
                sourceSize.width: width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)
                playing: visible
                asynchronous: true
                speed: Config.general.sessionGifSpeed
                source: Paths.absolutePath(Config.paths.sessionGif)
                fillMode: AnimatedImage.PreserveAspectFit
                opacity: Visibilities.isCaelestiaMode ? 0 : 1
                Behavior on opacity { Anim { type: Anim.Standard } }
                visible: Config.paths.sessionGif !== ""
            }

            AnimatedImage {
                anchors.fill: parent
                sourceSize.width: width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)
                playing: visible
                asynchronous: true
                speed: Config.general.sessionGifSpeed
                source: Paths.absolutePath("root:/assets/dino.gif")
                fillMode: AnimatedImage.PreserveAspectFit
                opacity: Visibilities.isCaelestiaMode ? 1 : 0
                Behavior on opacity { Anim { type: Anim.Standard } }
                
                layer.enabled: true
                layer.effect: Colouriser {
                    colorizationColor: Colours.palette.m3onSurface
                    sourceColor: "white"
                }
            }

            AnimatedImage {
                anchors.fill: parent
                sourceSize.width: width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)
                playing: visible
                asynchronous: true
                speed: Config.general.sessionGifSpeed
                source: Paths.absolutePath("root:/assets/dino.gif")
                fillMode: AnimatedImage.PreserveAspectFit
                opacity: Visibilities.isCaelestiaMode ? 1 : 0
                Behavior on opacity { Anim { type: Anim.Standard } }
                
                layer.enabled: true
                layer.effect: Colouriser {
                    colorizationColor: Colours.palette.m3onSurface
                    sourceColor: "white"
                }
            }
        }
    }

    Component {
        id: buttonComponent
        SessionButton {
            id: button
            
            icon: modelData.icon || "widgets"
            command: modelData.command || []
            
            // The Loader passes compId and itemIndex to its properties, but we access it from the Loader parent context
            
            property Item navUp: root.findFocusable(itemIndex, -1)
            property Item navDown: root.findFocusable(itemIndex, 1)

            KeyNavigation.up: navUp
            KeyNavigation.down: navDown
        }
    }

    component SessionButton: IconButton {
        id: buttonBase

        required property list<string> command

        function exec(): void {
            if (!SessionManager.exec(command))
                Quickshell.execDetached(command);
        }

        implicitWidth: Tokens.sizes.session.button
        implicitHeight: Tokens.sizes.session.button

        inactiveColour: activeFocus ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
        inactiveOnColour: activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
        radius: pressed ? Tokens.rounding.medium : activeFocus ? Tokens.rounding.extraLarge : Tokens.rounding.largeIncreased
        font: Tokens.font.icon.builders.large.scale(1.3).build()
        onClicked: exec()

        Keys.onEnterPressed: exec()
        Keys.onReturnPressed: exec()
        Keys.onEscapePressed: root.visibilities.session = false
        Keys.onPressed: event => {
            if (!Config.session.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if ((event.key === Qt.Key_J || event.key === Qt.Key_N) && KeyNavigation.down) {
                    KeyNavigation.down.focus = true;
                    event.accepted = true;
                } else if ((event.key === Qt.Key_K || event.key === Qt.Key_P) && KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab && KeyNavigation.down) {
                KeyNavigation.down.focus = true;
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                if (KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            }
        }
    }
}
