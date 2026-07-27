# Keeps ~/.config/quickshell/caelestia in sync with the installed
# caelestia-shell package version and tells quickshell where to find it.
if command -v caelestia-shell-setup >/dev/null 2>&1; then
    caelestia-shell-setup 2>/dev/null || true
fi
export QUICKSHELL_CONFIG=caelestia
