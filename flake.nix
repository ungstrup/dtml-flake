{
  description = "A flake wrapping the Darktide Mod Loader for Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    rust-overlay,
    crane,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [(import rust-overlay)];
        };
        rust = pkgs.rust-bin.stable.latest.default;
        craneLib = (crane.mkLib pkgs).overrideToolchain rust;
        dtkitPatchCrate = craneLib.buildPackage {
          pname = "dtkit-patch";
          version = "0.1.6";
          src = pkgs.fetchgit {
            url = "https://github.com/manshanko/dtkit-patch";
            rev = "e7e71dd1ae20e4d85c95350c4997143daff438ce";
            hash = "sha256-h/YS40IbCtOqzBorZMqM7Ef+OEhHwdEcuMfBQvy5pMA=";
          };
          strictDeps = true;
        };
        darktideModLoader = pkgs.fetchgit {
          url = "https://github.com/Darktide-Mod-Framework/Darktide-Mod-Loader";
          rev = "refs/tags/24.11.27";
          sparseCheckout = [
            "binaries"
            "bundle"
            "mods"
          ];
          hash = "sha256-h/YS40IbCtOqzBorZMqM7Ef+OEhHwdEcuMfBQvy5pMA=";
        };
        installer = pkgs.writeShellApplication {
          name = "install";
          runtimeInputs = [dtkitPatchCrate pkgs.jq];
          text = ''
            SOURCE_PATH="${darktideModLoader}/"
            PATCHER=dtkit-patch
            DT_PATH="$($PATCHER --meta | jq -r .steam)"
            DT_PATH="''${DT_PATH:-.}"

            if [ $# -eq 0 ]; then
                echo "Usage: $0 {install|uninstall|enable|disable}"
                exit 1
            fi

            case "$1" in
                install)
                    rsync -av --progress "$SOURCE_PATH" "$DT_PATH/"
                    chmod u+w "$DT_PATH/bundle" "$DT_PATH/mods"
                    $PATCHER --patch
                    ;;
                uninstall)
                    $PATCHER --unpatch
                    rm -R "$DT_PATH/mods"
                    rm -R "$DT_PATH/tools"
                    rm "$DT_PATH/binaries/mod_loader"
                    rm "$DT_PATH/bundle/9ba626afa44a3aa3.patch_999"
                    rm "$DT_PATH/README.md"
                    rm "$DT_PATH/toggle_darktide_mods.bat"
                    ;;
                enable)
                    $PATCHER --patch
                    ;;
                disable)
                    $PATCHER --unpatch
                    ;;
                *)
                    echo "Usage: $0 {install|uninstall|enable|disable}"
                    exit 1
                    ;;
            esac
          '';
        };
      in {
        packages = {
          inherit darktideModLoader;
          dtkitPatch = dtkitPatchCrate;
          modLoader = installer;
        };
        checks = {inherit dtkitPatchCrate installer;};
        devShells.default = craneLib.devShell {
          checks = self.checks.${system};
        };
      }
    );
}
