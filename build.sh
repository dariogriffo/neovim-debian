#!/bin/bash
set -euo pipefail
./build_neovim_debian.sh "$1" "$2"
./build_src.sh "$1" "$2"
