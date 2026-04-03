{
  description = "envora - Encrypted .env vault manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages = {
          envora = pkgs.callPackage ./default.nix {};
          default = self.packages.${system}.envora;
        };
      }
    ) // {
      overlays.default = final: prev: {
        envora = final.callPackage ./default.nix {};
      };
    };
}
