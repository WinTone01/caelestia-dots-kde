#!/usr/bin/env bash
# caelestia-shell-setup - deploys the packaged Caelestia shell config into
# the current user's quickshell config directory.
#
# Runs automatically once per login via /etc/profile.d/caelestia-shell.sh
# (a no-op there if already up to date). Safe to re-run manually, e.g.
# right after a `dnf upgrade` that bumped caelestia-shell:
#
#   caelestia-shell-setup            # sync only if the version changed
#   caelestia-shell-setup --force    # always re-sync
#
# Keep this file in sync with the Arch counterpart at
# sdata/arch-dist/caelestia-shell-setup.sh.

set -euo pipefail

SYSTEM_SHARE="/usr/share/caelestia-shell"
USER_CONFIG="${CAELESTIA_SHELL_CONFIG_DIR:-$HOME/.config/quickshell/caelestia}"
FORCE=0

for arg in "$@"; do
    case "$arg" in
        --force) FORCE=1 ;;
        *)
            echo "Usage: caelestia-shell-setup [--force]" >&2
            exit 1
            ;;
    esac
done

if [[ ! -d "$SYSTEM_SHARE" ]]; then
    echo "[ERR] $SYSTEM_SHARE not found - is caelestia-shell installed?" >&2
    exit 1
fi

PKG_VERSION="$(cat "$SYSTEM_SHARE/.version" 2>/dev/null || echo unknown)"
STAMP_FILE="$USER_CONFIG/.installed_version"
CURRENT_VERSION="$(cat "$STAMP_FILE" 2>/dev/null || echo '')"

if [[ "$FORCE" -eq 0 && "$PKG_VERSION" == "$CURRENT_VERSION" && -f "$USER_CONFIG/shell.qml" ]]; then
    exit 0
fi

mkdir -p "$USER_CONFIG"
rsync -a --delete --exclude '.installed_version' "$SYSTEM_SHARE/" "$USER_CONFIG/"
echo "$PKG_VERSION" > "$STAMP_FILE"

echo "[OK] Caelestia shell config deployed to $USER_CONFIG (version $PKG_VERSION)"
