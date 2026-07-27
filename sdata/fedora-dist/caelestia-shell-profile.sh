# Keeps ~/.config/quickshell/caelestia in sync with the installed
# caelestia-shell package version. A cheap no-op once already up to date.
if command -v caelestia-shell-setup >/dev/null 2>&1; then
    caelestia-shell-setup 2>/dev/null || true
fi
