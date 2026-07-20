#!/bin/bash
# Build Debian *source* packages (.dsc + .orig.tar.gz + .debian.tar.xz) for each
# suite, for upload to an apt repository (e.g. deb.griffo.io). The upstream
# Neovim source archive is used as the .orig tarball; the actual shipped payload
# is the prebuilt release binary, fetched by debian/rules at build time.
#
# Usage: ./build_src.sh <neovim_version> <build_version>
set -euo pipefail

VERSION="${1:-}"
BUILD="${2:-}"
if [ -z "$VERSION" ] || [ -z "$BUILD" ]; then
    echo "Usage: $0 <neovim_version> <build_version>" >&2
    echo "Example: $0 0.12.4 1" >&2
    exit 1
fi

PACKAGE_NAME="neovim-latest"
ORIG_TARBALL="${PACKAGE_NAME}_${VERSION}.orig.tar.gz"
BUILD_DIR="${PACKAGE_NAME}-${VERSION}"

# --- Shared .orig.tar.gz: the upstream source archive for tag v<VERSION> -----
# GitHub archive of tag "v<VERSION>" extracts to "neovim-<VERSION>/"; rename it
# to "neovim-latest-<VERSION>/" as dpkg-source expects <source>-<version>/.
if [ ! -f "$ORIG_TARBALL" ]; then
    echo "Downloading upstream source for v${VERSION}..."
    wget -q "https://github.com/neovim/neovim/archive/refs/tags/v${VERSION}.tar.gz" \
        -O "neovim-${VERSION}.tar.gz"
    tar -xf "neovim-${VERSION}.tar.gz"
    mv "neovim-${VERSION}" "${BUILD_DIR}"
    tar -czf "$ORIG_TARBALL" "${BUILD_DIR}"
    rm -rf "${BUILD_DIR}" "neovim-${VERSION}.tar.gz"
    echo "  Repacked as $ORIG_TARBALL"
else
    echo "  Using existing $ORIG_TARBALL"
fi

build_source_package() {
    local dist="$1"
    local FULL_VERSION="${VERSION}-${BUILD}~${dist}"
    echo "  Building source package for ${dist} (${FULL_VERSION})..."

    rm -rf "$BUILD_DIR"
    tar -xf "$ORIG_TARBALL"
    cp -r debian "$BUILD_DIR/"

    cat > "$BUILD_DIR/debian/changelog" << EOF
neovim-latest (${FULL_VERSION}) ${dist}; urgency=medium

  * New upstream release ${VERSION}.

 -- Dario Griffo <dariogriffo@gmail.com>  $(date -R)
EOF

    dpkg-source -b "$BUILD_DIR"
    rm -rf "$BUILD_DIR"
}

echo ""
echo "Building Debian source packages..."
for dist in "bookworm" "trixie" "forky" "sid"; do
    build_source_package "$dist"
done

echo ""
echo "Source packages created:"
ls -la "${PACKAGE_NAME}_"*.dsc "${PACKAGE_NAME}_"*.orig.tar.gz "${PACKAGE_NAME}_"*.debian.tar.xz 2>/dev/null || true
