{
  description = "envoy - Encrypted .env vault manager";

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
          envoy = pkgs.callPackage ./default.nix {};
          default = self.packages.${system}.envoy;
        };
      }
    ) // {
      overlays.default = final: prev: {
        envoy = final.callPackage ./default.nix {};
      };
    };
}
