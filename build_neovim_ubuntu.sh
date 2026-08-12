#!/bin/bash
# Build the neovim-latest binary packages (.deb) for each Ubuntu suite, using a
# per-suite Docker image so shared-library dependencies resolve correctly.
#
# Produces, per suite, in ./out — note the _ubu suffix the mirror's
# download_ubuntu_file.sh expects (dpkg-buildpackage doesn't add it, so we
# rename each suite's freshly-built debs in place):
#   neovim-latest_<ver>-<build>~<dist>_amd64_ubu.deb
#   neovim-latest-unstripped_<ver>-<build>~<dist>_amd64_ubu.deb
#   neovim-latest-runtime_<ver>-<build>~<dist>_all_ubu.deb
#
# Usage: ./build_neovim_ubuntu.sh <neovim_version> <build_version>
set -euo pipefail

VERSION="${1:-}"
BUILD="${2:-}"
if [ -z "$VERSION" ] || [ -z "$BUILD" ]; then
    echo "Usage: $0 <neovim_version> <build_version>" >&2
    echo "Example: $0 0.12.4 1" >&2
    exit 1
fi

DISTS=("jammy" "noble" "questing" "resolute")

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
        -f Dockerfile.ubu .

    cid="$(docker create "neovim-latest-build-${dist}")"
    docker cp "${cid}:/out/." ./out/
    docker rm "${cid}" > /dev/null

    # The mirror's download_ubuntu_file.sh looks for a _ubu.deb suffix, which
    # dpkg-buildpackage doesn't produce. Rename only THIS suite's fresh debs
    # (matched by ~<dist>_), skipping any already renamed on a re-run.
    for f in out/neovim-latest*~"${dist}"_*.deb; do
        case "$f" in
            *_ubu.deb) ;;
            *) mv "$f" "${f%.deb}_ubu.deb" ;;
        esac
    done
done

echo ""
echo "Built packages:"
ls -la out/*_ubu.deb
