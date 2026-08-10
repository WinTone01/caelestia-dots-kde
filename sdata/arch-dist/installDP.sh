#!/usr/bin/env bash
# installDP.sh - Arch package installation for Caelestia KDE Port

set -uo pipefail

log()  { echo -e "\033[0;36m[INFO]\033[0m $*"; }
err()  { echo -e "\033[0;31m[ERR]\033[0m  $*"; }

# Vicinae is installed from the tarball upstream publishes rather than the AUR,
# so the only party trusted is the project itself. That tarball is laid out as a
# prefix (bin/, libexec/, share/, lib/systemd/user/) and resolves its helpers
# relative to the binary, so it unpacks into /usr/local — already on systemd's
# user unit search path, so the service it ships is found as-is.
#
# What the AUR package did and this has to do by hand: verify the download,
# grant the input helper its capability, and load uinput. Its runtime
# dependencies stay with pacman, in UTILITY_PACKAGES.
VICINAE_VERSION="0.24.0"
# sha256 of vicinae-linux-x86_64-v0.24.0.tar.gz as published upstream; bump with
# VICINAE_VERSION.
VICINAE_SHA256="015a1ef2f8b23ea36a3f831a41de2d138f927cf45c987f62de3ec4add8dbafe7"
install_vicinae_tarball() {
    if [[ "$(uname -m)" != "x86_64" ]]; then
        err "Vicinae ships an x86_64 tarball only; on $(uname -m) install the AppImage from https://github.com/vicinaehq/vicinae/releases"
        return 1
    fi

    local url="https://github.com/vicinaehq/vicinae/releases/download/v${VICINAE_VERSION}/vicinae-linux-x86_64-v${VICINAE_VERSION}.tar.gz"
    local tmpdir
    tmpdir="$(mktemp -d)"

    log "Downloading Vicinae ${VICINAE_VERSION}..."
    if ! curl -fsSL "$url" -o "$tmpdir/vicinae.tar.gz"; then
        err "Failed to download Vicinae."
        rm -rf "$tmpdir"
        return 1
    fi

    # This unpacks as root into /usr/local, so the download is checked before it
    # is trusted, not after.
    local got
    got="$(sha256sum "$tmpdir/vicinae.tar.gz" | cut -d" " -f1)"
    if [[ "$got" != "$VICINAE_SHA256" ]]; then
        err "Vicinae checksum mismatch - refusing to install."
        err "  expected $VICINAE_SHA256"
        err "  got      $got"
        rm -rf "$tmpdir"
        return 1
    fi

    if ! sudo tar -xzf "$tmpdir/vicinae.tar.gz" -C /usr/local --strip-components=1; then
        err "Failed to unpack Vicinae into /usr/local."
        rm -rf "$tmpdir"
        return 1
    fi
    rm -rf "$tmpdir"
    sudo systemctl daemon-reload 2>/dev/null || true

    # Snippets and paste need the input helper to read /dev/input and inject
    # through /dev/uinput. The tarball ships the modules-load.d drop-in for the
    # latter, but that only applies at boot.
    sudo setcap "cap_dac_override+ep" /usr/local/libexec/vicinae/vicinae-input-server 2>/dev/null || \
        err "setcap failed; Vicinae snippets and paste will not work."
    sudo modprobe uinput 2>/dev/null || \
        log "Could not load uinput now; snippets and paste will work after a reboot."

    local missing
    missing="$(ldd /usr/local/bin/vicinae 2>/dev/null | awk '/not found/ {print "    " $1}')"
    if [[ -n "$missing" ]]; then
        err "Vicinae installed but is missing shared libraries:"
        printf '%s\n' "$missing"
        err "Install the packages providing those, then: systemctl --user restart vicinae"
        return 1
    fi

    log "Vicinae ${VICINAE_VERSION} installed to /usr/local."
    return 0
}


log "Installing Arch packages..."

INSTALL_FISH="${INSTALL_FISH:-true}"
INSTALL_PAPIRUS="${INSTALL_PAPIRUS:-true}"
INSTALL_DARKLY="${INSTALL_DARKLY:-true}"

# Ensure yay
if ! command -v yay >/dev/null 2>&1; then
    log "yay not found - installing..."
    sudo pacman -S --needed --noconfirm base-devel git || true
    tmpdir="$(mktemp -d)"
    git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmpdir"
    (
        cd "$tmpdir" || exit 1
        makepkg -si --noconfirm
    )
    rm -rf "$tmpdir"
fi

# Core dependencies split by group — controlled via PACKAGE_GROUP env var
PACKAGE_GROUP="${PACKAGE_GROUP:-all}"

CORE_PACKAGES=(
    cmake ninja ccache
    wl-clipboard cliphist wl-clip-persist inotify-tools app2unit wireplumber trash-cli jq aubio lm_sensors
    libpipewire glibc libcava qt6-declarative gcc-libs qt6-base qt6-declarative qt6-wayland libqalculate kpipewire kglobalaccel kglobalacceld libsecret
    ffmpeg
)

SHELL_PACKAGES=(
    caelestia-cli quickshell-git
    foot eza fastfetch starship btop bash
)

THEME_PACKAGES=(
    adw-gtk-theme ttf-jetbrains-mono-nerd ttf-material-symbols-variable ttf-rubik-vf ttf-cascadia-code-nerd
)

UTILITY_PACKAGES=(
    swappy brightnessctl ddcutil networkmanager imagemagick tesseract tesseract-data-eng satty spectacle xdg-utils sassc
    # Vicinae's runtime dependencies. The launcher itself comes from upstream's
    # tarball below rather than the AUR, but what it links against is ordinary
    # packaged software and is left to pacman. qt6-base, qt6-declarative and
    # libqalculate are already in CORE_PACKAGES.
    nodejs qt6-svg layer-shell-qt qtkeychain-qt6 syntax-highlighting
)

# Build final package list based on selected group
PACKAGES=()
case "$PACKAGE_GROUP" in
    core)   PACKAGES=("${CORE_PACKAGES[@]}") ;;
    shell)  PACKAGES=("${SHELL_PACKAGES[@]}") ;;
    themes) PACKAGES=("${THEME_PACKAGES[@]}") ;;
    utils)  PACKAGES=("${UTILITY_PACKAGES[@]}") ;;
    all|*)  PACKAGES=("${CORE_PACKAGES[@]}" "${SHELL_PACKAGES[@]}" "${THEME_PACKAGES[@]}" "${UTILITY_PACKAGES[@]}") ;;
esac

if [[ "$PACKAGE_GROUP" == "all" || "$PACKAGE_GROUP" == "shell" ]]; then
    if [[ "$INSTALL_FISH" == "true" ]]; then
        PACKAGES+=(fish)
    else
        log "Skipping Fish installation by user choice."
    fi
fi

if [[ "$PACKAGE_GROUP" == "all" || "$PACKAGE_GROUP" == "themes" ]]; then
    if [[ "$INSTALL_PAPIRUS" == "true" ]]; then
        PACKAGES+=(papirus-icon-theme)
    else
        log "Skipping Papirus icon theme installation by user choice."
    fi
    if [[ "$INSTALL_DARKLY" == "true" ]]; then
        PACKAGES+=(darkly)
    else
        log "Skipping Darkly package installation by user choice."
    fi
fi

log "Installing packages (group: $PACKAGE_GROUP)..."
FAILED_PKGS=()

# Batch install all packages at once — much faster than individual yay calls
if ! yay -S --needed --noconfirm "${PACKAGES[@]}"; then
    log "Batch install had failures. Retrying individually..."
    for pkg in "${PACKAGES[@]}"; do
        # Skip packages already installed by the batch attempt
        if pacman -Q "$pkg" >/dev/null 2>&1; then
            continue
        fi
        if ! yay -S --needed --noconfirm "$pkg"; then
            log "yay failed to install $pkg. Attempting manual build from AUR..."
            tmpdir="$(mktemp -d)"
            if git clone --depth 1 "https://aur.archlinux.org/${pkg}.git" "$tmpdir"; then
                (
                    cd "$tmpdir" || exit 1
                    makepkg -si --noconfirm
                ) || {
                    err "Manual build for $pkg failed."
                    FAILED_PKGS+=("$pkg")
                }
            else
                err "Could not find AUR repository for $pkg."
                FAILED_PKGS+=("$pkg")
            fi
            rm -rf "$tmpdir"
        fi
    done
fi

if [[ "$PACKAGE_GROUP" == "all" || "$PACKAGE_GROUP" == "utils" ]]; then
    if command -v vicinae >/dev/null 2>&1; then
        log "Vicinae already installed; skipping."
    else
        install_vicinae_tarball || FAILED_PKGS+=("vicinae")
    fi
fi

if [ ${#FAILED_PKGS[@]} -ne 0 ]; then
    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/caelestia-kde"
    err "The following packages could not be installed:"
    for pkg in "${FAILED_PKGS[@]}"; do
        err "  - $pkg"
        echo "$pkg" >> "${XDG_CACHE_HOME:-$HOME/.cache}/caelestia-kde/failed_packages.txt"
    done
fi

if command -v sassc >/dev/null 2>&1 && ! command -v sass >/dev/null 2>&1; then
    sudo ln -sf /usr/bin/sassc /usr/local/bin/sass || true
fi

log "Arch package installation complete."
