#!/bin/bash
# Build the neovim-latest binary packages (.deb) for each Debian suite, using a
# per-suite Docker image so shared-library dependencies resolve correctly.
#
# Produces, per suite, in ./out :
#   neovim-latest_<ver>-<build>~<dist>_amd64.deb
#   neovim-latest-unstripped_<ver>-<build>~<dist>_amd64.deb
#   neovim-latest-runtime_<ver>-<build>~<dist>_all.deb
#
# Usage: ./build_neovim_debian.sh <neovim_version> <build_version>
set -euo pipefail

VERSION="${1:-}"
BUILD="${2:-}"
if [ -z "$VERSION" ] || [ -z "$BUILD" ]; then
    echo "Usage: $0 <neovim_version> <build_version>" >&2
    echo "Example: $0 0.12.4 1" >&2
    exit 1
fi

DISTS=("bookworm" "trixie" "forky" "sid")

mkdir -p out

for dist in "${DISTS[@]}"; do
    FULL_VERSION="${VERSION}-${BUILD}~${dist}"
    echo "==> Building neovim-latest ${FULL_VERSION} (${dist})"

    # Generate the distribution-specific changelog (overwrites the placeholder).
    cat > debian/changelog << EOF
neovim-latest (${FULL_VERSION}) ${dist}; urgency=medium

  * New upstream release ${VERSION}.

 -- Dario Griffo <dariogriffo@gmail.com>  $(date -R)
EOF

    docker build -t "neovim-latest-build-${dist}" \
        --build-arg "DIST=${dist}" \
        -f Dockerfile .

    cid="$(docker create "neovim-latest-build-${dist}")"
    docker cp "${cid}:/out/." ./out/
    docker rm "${cid}" > /dev/null
done

echo ""
echo "Built packages:"
ls -la out/*.deb
