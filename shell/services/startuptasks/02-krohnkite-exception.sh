#!/usr/bin/env bash

IGNORE_CLASS=$(kreadconfig6 --file kwinrc --group Script-krohnkite --key ignoreClass 2>/dev/null)
if [[ -z "$IGNORE_CLASS" ]]; then
    # Default list if missing, plus quickshell
    NEW_IGNORE="krunner,yakuake,spectacle,kded5,xwaylandvideobridge,plasmashell,ksplashqml,org.kde.plasmashell,org.kde.polkit-kde-authentication-agent-1,quickshell"
else
    if ! echo "$IGNORE_CLASS" | grep -q '\bquickshell\b'; then
        NEW_IGNORE="${IGNORE_CLASS},quickshell"
    else
        NEW_IGNORE="$IGNORE_CLASS"
    fi
fi
kwriteconfig6 --file kwinrc --group Script-krohnkite --key ignoreClass "$NEW_IGNORE"

echo "StartupTasks: Added quickshell to Krohnkite exceptions"

# Return 1 to indicate KWin reconfigure is needed
exit 1
