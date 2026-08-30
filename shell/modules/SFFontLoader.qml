import QtQuick
import Quickshell

// Loads the SF Pro variable font (upright + italic) so the shell can use it
// when the sans font family is set to "SF Pro". A variable font covers every
// weight, so no per-weight static files are needed.
QtObject {
    FontLoader {
        source: Quickshell.shellPath("assets/fonts/SF-Pro/SF-Pro.ttf")
    }
    FontLoader {
        source: Quickshell.shellPath("assets/fonts/SF-Pro/SF-Pro-Italic.ttf")
    }
}
