pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Config
import qs.utils

QtObject {
    id: root

    /// Curated categories shown in the app browser sidebar. Each entry's `xdg`
    /// lists the XDG desktop-entry `Categories=` values mapped to that group.
    readonly property var definitions: [
        { id: "favorites", name: qsTr("Favorites"), icon: "favorite" },
        { id: "all", name: qsTr("All Applications"), icon: "apps" },
        { id: "development", name: qsTr("Development"), icon: "code", xdg: ["Development"] },
        { id: "graphics", name: qsTr("Graphics"), icon: "palette", xdg: ["Graphics"] },
        { id: "system", name: qsTr("System"), icon: "settings", xdg: ["System", "Settings"] },
        { id: "utilities", name: qsTr("Utilities"), icon: "build", xdg: ["Utility"] },
        { id: "network", name: qsTr("Network"), icon: "public", xdg: ["Network"] },
        { id: "multimedia", name: qsTr("Multimedia"), icon: "movie", xdg: ["AudioVideo", "Audio", "Video"] },
        { id: "office", name: qsTr("Office"), icon: "description", xdg: ["Office"] },
        { id: "education", name: qsTr("Education"), icon: "school", xdg: ["Education"] },
        { id: "science", name: qsTr("Science"), icon: "science", xdg: ["Science"] },
        { id: "games", name: qsTr("Games"), icon: "sports_esports", xdg: ["Game"] },
        { id: "help", name: qsTr("Help"), icon: "help", xdg: ["Help"] },
        { id: "other", name: qsTr("Other"), icon: "more_horiz" }
    ]

    /// The curated category a desktop entry belongs to, or "other".
    function categoryForApp(app): string {
        const cats = (app.categories || "").split(";").map(c => c.trim()).filter(c => c.length > 0);
        for (const def of root.definitions) {
            if (!def.xdg) continue;
            for (const x of def.xdg)
                if (cats.includes(x)) return def.id;
        }
        return "other";
    }

    /// Visible apps for a category, kept in the caller-provided order.
    function appsFor(categoryId: string, all: list<var>): list<var> {
        if (categoryId === "all")
            return all;
        if (categoryId === "favorites")
            return all.filter(a => Strings.testRegexList(GlobalConfig.launcher.favouriteApps, a.id));
        if (categoryId === "other")
            return all.filter(a => root.categoryForApp(a) === "other");
        return all.filter(a => root.categoryForApp(a) === categoryId);
    }
}
