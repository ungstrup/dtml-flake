{
  description = "A flake wrapping the Darktide Mod Loader for Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
  }: {
    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    packages.x86_64-linux.default = self.packages.x86_64-linux.hello;
  };
}
