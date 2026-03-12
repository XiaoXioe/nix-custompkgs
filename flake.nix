{
  description = "Koleksi custom Nix packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system} = {
        uabea = pkgs.callPackage ./pkgs/uabea/default.nix { };
        vimmdl = pkgs.callPackage ./pkgs/vimms-lair/default.nix { };
        freqtrade = pkgs.callPackage ./pkgs/freqtrade/default.nix { };
      };
    };
}
