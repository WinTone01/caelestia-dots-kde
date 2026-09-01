pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.items
import qs.modules.launcher.services

component CategoryButton: Item {
    id: catRoot

    required property var modelData
    required property bool selected

    signal clicked()

    implicitHeight: 40

    StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.medium
        color: Colours.palette.m3onSurface
        opacity: catRoot.selected ? 0.10 : (catHover.containsMouse ? 0.05 : 0)

        Behavior on opacity {
            Anim {
                type: Anim.StandardSmall
            }
        }
    }

    StateLayer {
        id: catHover

        anchors.fill: parent
        radius: Tokens.rounding.medium
        acceptedButtons: Qt.LeftButton
        onClicked: catRoot.clicked()
    }

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: catRoot.modelData?.icon ?? "apps"
            color: catRoot.selected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: catRoot.modelData?.name ?? ""
            color: catRoot.selected ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.large
            elide: Text.ElideRight
            width: catRoot.width - Tokens.padding.medium * 2 - 24 - Tokens.spacing.medium
        }
    }
}

Item {
    id: root

    required property DrawerVisibilities visibilities

    property string currentCategory: "favorites"
    property bool sidebarFocused: false

    readonly property var currentItem: grid.currentItem
    readonly property int count: grid.count

    readonly property int padding: Tokens.padding.large
    readonly property int sidebarWidth: Tokens.sizes.launcher.browseSidebarWidth
    readonly property int tileCellWidth: Tokens.sizes.launcher.browseTileWidth + Tokens.spacing.medium
    readonly property int tileCellHeight: Tokens.sizes.launcher.browseTileHeight + Tokens.spacing.medium

    function refresh(): void {
        gridModel.values = Categories.appsFor(root.currentCategory, Apps.allApps());
    }

    function launch(app): void {
        Apps.launch(app);
        root.visibilities.launcher = false;
    }

    function selectTile(index: int): void {
        grid.currentIndex = index;
    }

    function selectCategory(id: string): void {
        root.currentCategory = id;
        root.sidebarFocused = false;
        const idx = Categories.definitions.findIndex(d => d.id === id);
        sidebar.currentIndex = Math.max(0, idx);
        root.refresh();
        grid.currentIndex = grid.count > 0 ? 0 : -1;
    }

    // Keyboard entry points, invoked from the search field's Keys handlers.
    function incrementCurrentIndex(): void { // Down
        if (root.sidebarFocused)
            sidebar.incrementCurrentIndex();
        else
            grid.moveCurrentIndexDown();
    }

    function decrementCurrentIndex(): void { // Up
        if (root.sidebarFocused)
            sidebar.decrementCurrentIndex();
        else
            grid.moveCurrentIndexUp();
    }

    function moveLeft(): void {
        if (root.sidebarFocused)
            return;
        const before = grid.currentIndex;
        grid.moveCurrentIndexLeft();
        if (grid.currentIndex === before)
            root.sidebarFocused = true;
    }

    function moveRight(): void {
        if (root.sidebarFocused)
            root.selectCategory(sidebar.currentItem?.modelData?.id ?? "favorites");
        else
            grid.moveCurrentIndexRight();
    }

    function toggleFocus(): void {
        root.sidebarFocused = !root.sidebarFocused;
    }

    function activateCurrent(): void {
        if (root.sidebarFocused)
            root.selectCategory(sidebar.currentItem?.modelData?.id ?? "favorites");
        else if (grid.currentItem?.modelData)
            root.launch(grid.currentItem.modelData);
    }

    Component.onCompleted: {
        root.refresh();
        grid.currentIndex = grid.count > 0 ? 0 : -1;
        sidebar.currentIndex = 0;
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: Tokens.spacing.medium

        // Sidebar
        Item {
            Layout.preferredWidth: root.sidebarWidth
            Layout.fillHeight: true

            ListView {
                id: sidebar

                anchors.fill: parent

                model: Categories.definitions
                spacing: Tokens.spacing.extraSmall
                clip: true

                currentIndex: 0
                highlightFollowsCurrentItem: false
                highlight: Item {}

                delegate: CategoryButton {
                    required property var modelData
                    required property int index

                    width: parent?.width ?? 0
                    selected: sidebar.currentIndex === index
                    onClicked: root.selectCategory(root.modelData.id)
                }
            }
        }

        // Grid
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridView {
                id: grid

                anchors.fill: parent

                model: ScriptModel {
                    id: gridModel

                    values: []
                    onValuesChanged: grid.currentIndex = grid.count > 0 ? 0 : -1
                }

                cellWidth: root.tileCellWidth
                cellHeight: root.tileCellHeight
                clip: true

                currentIndex: -1
                highlightFollowsCurrentItem: false
                cacheBuffer: root.tileCellHeight * 4

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: grid
                }

                delegate: AppTile {
                    required property var modelData
                    required property int index

                    browser: root
                    selected: grid.currentIndex === index
                }
            }

            // Empty category state
            Column {
                anchors.centerIn: parent
                spacing: Tokens.spacing.medium
                visible: grid.count === 0

                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "apps"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.extraLarge
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("No apps in this category")
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.builders.large.weight(Font.Medium).build()
                }
            }
        }
    }
}
