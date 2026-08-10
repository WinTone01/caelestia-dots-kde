#!/usr/bin/env bash
# 06-services.sh  Enable systemd user services and reload KWin.

set -euo pipefail

BUNDLE_DIR="${BUNDLE_DIR:?BUNDLE_DIR not set}"

echo
echo ""
echo "  Step 6/11  Services & KWin"
echo ""

if systemctl --user is-enabled --quiet qs-kwin-bridge.service 2>/dev/null || \
   systemctl --user is-active --quiet qs-kwin-bridge.service 2>/dev/null; then
    echo "  Disabling legacy qs-kwin-bridge service..."
    systemctl --user disable --now qs-kwin-bridge.service 2>/dev/null || true
fi

echo "  Clearing legacy KWin workspace shortcuts to avoid QML conflicts..."
for i in $(seq 1 10); do
    kwriteconfig6 --file kglobalshortcutsrc --group "kwin" --key "Switch to Desktop $i" "none,none,Switch to Desktop $i"
    kwriteconfig6 --file kglobalshortcutsrc --group "kwin" --key "Window to Desktop $i" "none,none,Move Window to Desktop $i"
done

echo "  Disabling legacy quickshell-kde-bridge KWin script..."
kwriteconfig6 --file kwinrc --group "Plugins" --key "quickshell-kde-bridgeEnabled" "false"

echo "  Ensuring KWin has 5 virtual desktops..."
kwriteconfig6 --file kwinrc --group "Desktops" --key "Number" "5"
kwriteconfig6 --file kwinrc --group "Desktops" --key "Rows" "1"
for i in $(seq 1 5); do
    kwriteconfig6 --file kwinrc --group "Desktops" --key "Name_$i" "Desktop $i"
done

#  ydotoold (on-screen keyboard key injection)
# ydotoold needs access to /dev/uinput. Add a udev rule to allow the 'input'
# group to access it, then add the user to that group.
echo "  Applying system-level configurations (requires root)..."
sudo bash -s -- "$USER" << 'EOF'
TARGET_USER="$1"

if systemctl is-enabled --quiet keyd.service 2>/dev/null || \
   systemctl is-active --quiet keyd.service 2>/dev/null; then
    echo "  Disabling legacy keyd service..."
    systemctl disable --now keyd.service 2>/dev/null || true
fi

echo "  Setting up ydotoold (OSK key injection daemon)..."

if [[ ! -f /etc/udev/rules.d/80-uinput.rules ]]; then
    echo 'KERNEL=="uinput", GROUP="input", MODE="0660"' > /etc/udev/rules.d/80-uinput.rules
    udevadm control --reload-rules 2>/dev/null || true
    udevadm trigger 2>/dev/null || true
    echo "  [OK]  udev rule for uinput created."
fi

if ! groups "$TARGET_USER" | grep -q '\binput\b'; then
    usermod -aG input "$TARGET_USER"
    echo "  [OK]  Added $TARGET_USER to 'input' group (takes effect on next login)."
else
    echo "  [OK]  $TARGET_USER already in 'input' group."
fi

if [[ -e /dev/uinput ]]; then
    UINPUT_PERMS=$(stat -c "%a" /dev/uinput 2>/dev/null)
    UINPUT_GROUP=$(stat -c "%G" /dev/uinput 2>/dev/null)
    if [[ "$UINPUT_PERMS" != *"660" ]] || [[ "$UINPUT_GROUP" != "input" ]]; then
        chmod 660 /dev/uinput 2>/dev/null || true
        chgrp input /dev/uinput 2>/dev/null || true
    fi
fi
EOF

# Deploy ydotoold-wrapper script to ~/.local/bin
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/ydotoold-wrapper" << 'WRAPPER'
#!/bin/bash
# ydotoold-wrapper  starts ydotoold with uinput access (user is in 'input' group)
SOCKET="${YDOTOOL_SOCKET:-/run/user/$(id -u)/.ydotool_socket}"
if [ -S "$SOCKET" ] && pidof ydotoold > /dev/null 2>&1; then
    exit 0
fi
exec /usr/bin/ydotoold \
    --socket-path="$SOCKET" \
    --socket-perm=0660
WRAPPER
chmod +x "$HOME/.local/bin/ydotoold-wrapper"
echo "  [OK]  ydotoold-wrapper deployed to ~/.local/bin."

# Deploy and enable ydotoold systemd user service
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/ydotoold.service" << 'UNIT'
[Unit]
Description=ydotoold key injection daemon
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/ydotoold-wrapper
Restart=on-failure
Environment=YDOTOOL_SOCKET=/run/user/%U/.ydotool_socket

[Install]
WantedBy=graphical-session.target
UNIT
systemctl --user daemon-reload
systemctl --user enable ydotoold.service 2>/dev/null || true
systemctl --user start ydotoold.service 2>/dev/null || \
    echo "  [INFO] ydotoold will start on next login."
echo "  [OK]  ydotoold service configured."

#  Vicinae (replaces KRunner)
# KRunner is D-Bus activated, so stopping it is not enough — the next lookup
# would start it straight back up. Masking is what actually keeps it down.
echo "  Disabling KRunner..."
systemctl --user mask plasma-krunner.service 2>/dev/null || true
systemctl --user stop plasma-krunner.service 2>/dev/null || true
pkill -x krunner 2>/dev/null || true

if command -v vicinae >/dev/null 2>&1; then
    echo "  Enabling Vicinae launcher daemon..."
    # The package ships its own unit; only write one if it did not.
    if [[ ! -f /usr/lib/systemd/user/vicinae.service && ! -f "$HOME/.config/systemd/user/vicinae.service" ]]; then
        mkdir -p "$HOME/.config/systemd/user"
        cat > "$HOME/.config/systemd/user/vicinae.service" <<'UNIT'
[Unit]
Description=Vicinae Launcher Daemon
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=vicinae server --replace
Restart=always
RestartSec=5
KillMode=process

[Install]
WantedBy=graphical-session.target
UNIT
    fi

    # Alt+Space is what KRunner used and is free here; Caelestia keeps Meta and
    # Meta+Space for its own launcher, so the two do not fight over a key.
    mkdir -p "$HOME/.local/share/applications"
    cat > "$HOME/.local/share/applications/vicinae-toggle.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Toggle Vicinae
Comment=Show or hide the Vicinae launcher
Exec=vicinae toggle
Icon=vicinae
Terminal=false
NoDisplay=true
DESKTOP
    kwriteconfig6 --file kglobalshortcutsrc --group services \
        --group "vicinae-toggle.desktop" --key "_launch" "Alt+Space,none,Toggle Vicinae"

    #  Material palette -> Vicinae theme
    # Vicinae watches its theme directory, so regenerating the file is enough
    # for a running instance to pick the new colours up.
    if [[ -x "$BUNDLE_DIR/shell/scripts/vicinae-theme.py" ]]; then
        mkdir -p "$HOME/.local/bin"
        install -m755 "$BUNDLE_DIR/shell/scripts/vicinae-theme.py" "$HOME/.local/bin/caelestia-vicinae-theme"
        "$HOME/.local/bin/caelestia-vicinae-theme" 2>/dev/null || \
            echo "  [INFO] No scheme yet; the theme will be written on the next scheme change."

        cat > "$HOME/.config/systemd/user/caelestia-vicinae-theme.service" <<'UNIT'
[Unit]
Description=Regenerate the Vicinae theme from Caelestia's colour scheme

[Service]
Type=oneshot
ExecStart=%h/.local/bin/caelestia-vicinae-theme
UNIT
        cat > "$HOME/.config/systemd/user/caelestia-vicinae-theme.path" <<'UNIT'
[Unit]
Description=Watch Caelestia's colour scheme for Vicinae

[Path]
PathModified=%h/.local/state/caelestia/scheme.json

[Install]
WantedBy=graphical-session.target
UNIT
        systemctl --user enable caelestia-vicinae-theme.path 2>/dev/null || true
    fi

    systemctl --user daemon-reload
    systemctl --user enable vicinae.service 2>/dev/null || true
    systemctl --user start vicinae.service 2>/dev/null || \
        echo "  [INFO] Vicinae will start on next login."
    systemctl --user start caelestia-vicinae-theme.path 2>/dev/null || true
    echo "  [OK]  Vicinae configured (Alt+Space)."
else
    echo "  [INFO] vicinae not installed; skipping launcher setup."
fi

echo "[OK]  Services configured."
