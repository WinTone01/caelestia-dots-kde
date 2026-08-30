import QtQuick
import Quickshell

// Loads the bundled San Francisco fonts so the shell can use them.
// - SF Pro is a variable font (upright + italic), covering every weight in two files.
// - SF Mono ships as static per-weight files, so each weight is loaded separately.
// Item (not QtObject) is the root because QtObject has no default property and
// cannot hold FontLoader children.
Item {
    FontLoader {
        source: Quickshell.shellPath("assets/fonts/SF-Pro/SF-Pro.ttf")
    }
    FontLoader {
        source: Quickshell.shellPath("assets/fonts/SF-Pro/SF-Pro-Italic.ttf")
    }

    FontLoader {
        source: Quickshell.shellPath("assets/fonts/SF-Mono/SF-Mono-Light.otf")
    }
    FontLoader {
        source: Quickshell.shellPath("assets/fonts/SF-Mono/SF-Mono-LightItalic.otf")
    }
    FontLoader {
        source: Quickshell.shellPath("assets/fonts/SF-Mono/SF-Mono-Regular.otf")
    }
    FontLoader {
        source: Quickshell.shellPath("assets/fonts/SF-Mono/SF-Mono-RegularItalic.otf")
    }
    FontLoader {
        source: Quickshell.shellPath("assets/fonts/SF-Mono/SF-Mono-Medium.otf")
    }
    FontLoader {
        source: Quickshell.shellPath("assets/fonts/SF-Mono/SF-Mono-MediumItalic.otf")
    }
    FontLoader {
        source: Quickshell.shellPath("assets/fonts/SF-Mono/SF-Mono-Semibold.otf")
    }
    FontLoader {
        source: Quickshell.shellPath("assets/fonts/SF-Mono/SF-Mono-SemiboldItalic.otf")
    }
    FontLoader {
        source: Quickshell.shellPath("assets/fonts/SF-Mono/SF-Mono-Bold.otf")
    }
    FontLoader {
        source: Quickshell.shellPath("assets/fonts/SF-Mono/SF-Mono-BoldItalic.otf")
    }
    FontLoader {
        source: Quickshell.shellPath("assets/fonts/SF-Mono/SF-Mono-Heavy.otf")
    }
    FontLoader {
        source: Quickshell.shellPath("assets/fonts/SF-Mono/SF-Mono-HeavyItalic.otf")
    }
}
