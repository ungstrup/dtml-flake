# dtml-flake

A flake wrapping the Darktide Mod Loader for Nix

## Quick Start

1. Locate your Darktide install (probably
`$HOME/.local/share/Steam/steamapps/common/Warhammer 40,000 DARKTIDE`).
2. Open a terminal and `cd` to the install directory.
3. `nix run github:capslock/dtml-flake#modLoader install`

## Usage

* Install mod loader: `nix run github:capslock/dtml-flake#modLoader install`
* Uninstall mod loader: `nix run github:capslock/dtml-flake#modLoader uninstall`
* Enable mods: `nix run github:capslock/dtml-flake#modLoader enable`
* Disable mods: `nix run github:capslock/dtml-flake#modLoader disable`
