# caelestia-shell.spec
#
# Build via COPR (recommended): this repo ships .copr/Makefile, so a COPR
# project configured with the "GitHub / SCM" source method and this repo's
# URL builds and hosts precompiled RPMs automatically on every release -
# users then just:
#
#   sudo dnf copr enable <maintainer>/caelestia-shell
#   sudo dnf install caelestia-shell
#
# Alternatively, every GitHub Release also has a plain .rpm attached by CI
# (see .github/workflows/package-artifacts.yml, job build-fedora-binary) -
# download it and install directly with:
#
#   sudo dnf install ./caelestia-shell-*.rpm
#
# Build notes (only needed if building from source with rpmbuild directly):
#   - Requires the COPR repo celestelove/libcava enabled for libcava-devel,
#     which is not present in the standard Fedora repos (see
#     sdata/fedora-dist/installDP_fedora.sh for the exact `dnf copr enable`
#     invocation this project already uses for that same dependency).
#   - Source0 is the *full* source tarball (git submodules included) that
#     the "Package Artifacts" GitHub Actions workflow attaches to every
#     GitHub Release, because rpmbuild has no native way to fetch git
#     submodules the way `makepkg` does for the Arch package.
#   - Companion files in this directory:
#       caelestia-shell-setup.sh    - per-user config deployment helper
#       caelestia-shell-profile.sh  - /etc/profile.d hook that runs it

%global reponame caelestia-dots-kde

Name:           caelestia-shell
Version:        2.2.2
Release:        1%{?dist}
Summary:        Compiled QML shell plugins and default config for the Caelestia KDE port
License:        GPL-3.0-only
URL:            https://github.com/ladybug-me/%{reponame}
Source0:        %{url}/releases/download/v%{version}/%{reponame}-%{version}-full-src.tar.gz
Source1:        caelestia-shell-setup.sh
Source2:        caelestia-shell-profile.sh

BuildRequires:  cmake ninja-build gcc-c++ pkgconfig rsync
BuildRequires:  qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtwayland-devel
BuildRequires:  qt6-qtsvg-devel qt6-qtshadertools-devel
BuildRequires:  kf6-kglobalaccel-devel kpipewire-devel kf6-kwindowsystem-devel
BuildRequires:  libqalculate-devel aubio-devel libcava-devel
BuildRequires:  lm_sensors-devel libsecret-devel pipewire-devel

Requires:       qt6-qtbase qt6-qtdeclarative qt6-qtwayland qt6-qtsvg
Requires:       libqalculate aubio libcava lm_sensors libsecret
Requires:       kpipewire wireplumber rsync
Requires:       quickshell-git

%description
Caelestia is a community KDE port of the celestial-themed Hyprland
dotfiles, providing native C++/QML shell plugins for the launcher, bar,
notifications, lock screen, and more. This package ships the compiled
Quickshell modules and the default shell configuration.

%prep
%autosetup -n %{reponame}-%{version}

%build
cmake -S shell -B shell/build -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=%{_prefix} \
    -DINSTALL_LIBDIR=%{_lib}/caelestia \
    -DINSTALL_QMLDIR=%{_lib}/qt6/qml \
    -DINSTALL_QSCONFDIR=%{_datadir}/caelestia-shell \
    -DVERSION="v%{version}" \
    -DDISTRIBUTOR=fedora
cmake --build shell/build

%install
DESTDIR=%{buildroot} cmake --install shell/build

install -d -m 755 "%{buildroot}%{_datadir}/caelestia-shell/assets/icons"
if [ -d src/yet-another-monochrome-icon-set ]; then
    cp -a src/yet-another-monochrome-icon-set \
        "%{buildroot}%{_datadir}/caelestia-shell/assets/icons/yet-another-monochrome-icon-set"
fi
echo "%{version}" > "%{buildroot}%{_datadir}/caelestia-shell/.version"

install -Dm755 %{SOURCE1} "%{buildroot}%{_bindir}/caelestia-shell-setup"
install -Dm644 %{SOURCE2} "%{buildroot}%{_sysconfdir}/profile.d/caelestia-shell.sh"

%files
%license LICENSE
%{_libdir}/caelestia/
%{_libdir}/qt6/qml/Caelestia/
%{_datadir}/caelestia-shell/
%{_bindir}/caelestia-shell-setup
%{_sysconfdir}/profile.d/caelestia-shell.sh

%post
echo "caelestia-shell installed. Run 'caelestia-shell-setup' (or log in again) to deploy the config to ~/.config/quickshell/caelestia."

%postun
if [ "$1" -eq 0 ]; then
    echo "caelestia-shell removed. Your existing ~/.config/quickshell/caelestia was left in place."
fi

%changelog
* Mon Jul 27 2026 ladybug-me <noreply@github.com> - 2.2.2-1
- Initial RPM packaging of caelestia-shell
