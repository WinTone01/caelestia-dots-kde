# .copr/Makefile - lets a COPR project build caelestia-shell.spec directly
# from this repo via the "SCM" source method:
#
#   1. Create a project at https://copr.fedorainfracloud.org
#   2. Add a package with source type "SCM"
#      - Clone URL:   this repo's URL
#      - Subdirectory: (leave blank, repo root)
#      - Spec file:    sdata/fedora-dist/caelestia-shell.spec
#   3. Enable "Auto-rebuild" (webhook) so new tags/commits rebuild
#      automatically and COPR hosts the resulting RPMs as a real dnf repo.
#
# End users then just:
#   sudo dnf copr enable <maintainer>/caelestia-shell
#   sudo dnf install caelestia-shell
#
# COPR's build service invokes `make srpm outdir=$(RESULTDIR)` - this
# target must produce a .src.rpm in $$outdir using only the checked-out
# repo (network access to fetch Source0 is available during this step).

outdir ?= $(shell pwd)
topdir := $(shell mktemp -d)
spec := sdata/fedora-dist/caelestia-shell.spec

.PHONY: srpm
srpm:
	dnf install -y rpmdevtools rpm-build
	rpmdev-setuptree --root "$(topdir)"
	cp "$(spec)" "$(topdir)/SPECS/"
	cp sdata/fedora-dist/caelestia-shell-setup.sh "$(topdir)/SOURCES/"
	cp sdata/fedora-dist/caelestia-shell-profile.sh "$(topdir)/SOURCES/"
	cp sdata/fedora-dist/caelestia-shell.desktop "$(topdir)/SOURCES/"
	spectool -g -R --directory "$(topdir)/SOURCES" "$(topdir)/SPECS/caelestia-shell.spec"
	rpmbuild -bs --define "_topdir $(topdir)" --define "_srcrpmdir $(outdir)" "$(topdir)/SPECS/caelestia-shell.spec"
