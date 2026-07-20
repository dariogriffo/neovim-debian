![GitHub Release](https://img.shields.io/github/v/release/dariogriffo/neovim-debian)
![GitHub Release Date](https://img.shields.io/github/release-date/dariogriffo/neovim-debian)

# Neovim (latest) for Debian

This repository contains build scripts that produce **unofficial** Debian
packages (`.deb`) of the latest [Neovim](https://github.com/neovim/neovim)
release, hosted at [deb.griffo.io](https://deb.griffo.io).

The packages repackage the **official upstream prebuilt binary**
(`nvim-linux-x86_64.tar.gz`) — nothing is rebuilt from source — so Debian
**stable** users can get the newest Neovim the day it ships upstream, instead of
waiting for the next Debian release.

Currently supported Debian suites (amd64):

- Bookworm
- Trixie
- Forky
- Sid

## Packages

| Package | Arch | Contents |
| --- | --- | --- |
| `neovim-latest` | amd64 | The stripped `nvim` binary and the tree-sitter parsers. Provides `/usr/bin/nvim` and the `editor` alternative. |
| `neovim-latest-runtime` | all | The architecture-independent runtime (syntax, indent, colourschemes, standard plugins, docs, man page, desktop entry). |
| `neovim-latest-unstripped` | amd64 | Optional: the same `nvim` binary with upstream debug symbols kept, for backtraces/debugging. |

`neovim-latest` `Provides`/`Conflicts`/`Replaces` Debian's own `neovim`, so
installing it cleanly takes over `/usr/bin/nvim`. The command is still `nvim`.

## Install / Update

### The Debian way (apt)

```sh
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://deb.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/deb.griffo.io.gpg
echo "deb [signed-by=/etc/apt/keyrings/deb.griffo.io.gpg] https://deb.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/deb.griffo.io.list
sudo apt update
sudo apt install neovim-latest
```

Optionally install the debug-symbol variant alongside and switch between them:

```sh
sudo apt install neovim-latest-unstripped
sudo update-alternatives --config nvim
```

### Manual installation

1. Download the `.deb` files for your Debian suite from the
   [Releases](https://github.com/dariogriffo/neovim-debian/releases) page
   (`neovim-latest-runtime` + `neovim-latest`).
2. Install them:

```sh
sudo dpkg -i neovim-latest-runtime_*.deb neovim-latest_*.deb
```

## Updating

Just re-run any install method above; the package will be upgraded in place.
There is no need to uninstall the previous version.

## Building locally

Requires Docker (for the binary packages) and `dpkg-dev`/`devscripts` (for the
source packages):

```sh
./build_neovim_debian.sh 0.12.4 1   # -> ./out/*.deb
./build_src.sh           0.12.4 1   # -> *.dsc / *.orig.tar.gz / *.debian.tar.xz
```

## How releases work

A scheduled workflow (`check-upstream.yml`) compares the latest upstream Neovim
release against the latest release published here and, when they differ,
dispatches `release.yml`, which validates the upstream licence, builds all
packages for every suite, and publishes a GitHub Release.

## Disclaimer

- This is an unofficial community packaging project. For Neovim itself, see
  [neovim/neovim](https://github.com/neovim/neovim).
- This repo is not for Neovim bug reports — only for the Debian packaging.
- Inspired by the packaging approach of
  [bun-debian](https://github.com/dariogriffo/bun-debian).
