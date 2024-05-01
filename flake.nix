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
            hash = "sha256-pGTS0Jk6ZxJj36cjQty/fLKDi67SVPBOp/wyylIfWZ0=";
          };
          strictDeps = true;
        };
        darktideModLoader = pkgs.fetchgit {
          url = "https://github.com/Darktide-Mod-Framework/Darktide-Mod-Loader";
          rev = "refs/tags/23.12.11";
          sparseCheckout = [
            "binaries"
            "bundle"
            "mods"
          ];
          hash = "sha256-H+RNawoEThmZpgQS+HKdD26cLTRxZ7ywM2yldGpvs84=";
        };
        installer = pkgs.writeShellApplication {
          name = "install";
          runtimeInputs = [dtkitPatchCrate];
          text = ''
            SOURCE_PATH="${darktideModLoader}/"
            PATCHER=dtkit-patch

            case "$1" in
                install)
                    rsync -av --progress "$SOURCE_PATH" .
                    chmod u+w bundle mods
                    $PATCHER --patch bundle
                    ;;
                uninstall)
                    $PATCHER --unpatch bundle
                    rm -R mods
                    rm -R tools
                    rm binaries/mod_loader
                    rm bundle/9ba626afa44a3aa3.patch_999
                    rm README.md
                    rm toggle_darktide_mods.bat
                    ;;
                enable)
                    $PATCHER --patch bundle
                    ;;
                disable)
                    $PATCHER --unpatch bundle
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
