import QtQuick
import Quickshell
import Caelestia.Models

// Loads every font the shell ships with or the user drops into assets/fonts.
// - The bundled Google Sans Flex is loaded explicitly.
// - Any .ttf/.otf found under assets/fonts (e.g. SF-Pro/, SF-Mono/, or your
//   own folder) is picked up automatically, so adding a font never requires
//   touching this file.
Item {
    FontLoader {
        source: Quickshell.shellPath("assets/google-sans-flex/GoogleSansFlex-Subset.ttf")
    }

    FileSystemModel {
        id: fontsModel

        recursive: true
        path: Quickshell.shellPath("assets/fonts")
        filter: FileSystemModel.Files
        nameFilters: ["*.ttf", "*.otf"]
    }

    Repeater {
        model: fontsModel

        delegate: Item {
            FontLoader {
                source: "file://" + modelData.path
            }
        }
    }
}
