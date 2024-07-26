{
  description = "create-melange-app Nix Flake";

  inputs.nix-filter.url = "github:numtide/nix-filter";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs = {
    url = "github:nix-ocaml/nix-overlays";
    inputs.flake-utils.follows = "flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    nix-filter,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages."${system}".extend (self: super: {
        ocamlPackages = super.ocaml-ng.ocamlPackages_5_2.overrideScope (oSelf: oSuper: {
          dune_3 = oSuper.dune_3.overrideAttrs (_: {
            configureFlags = [
              "--enable-toolchains"
              "--enable-pkg-build-progress"
              "--enable-lock-dev-tool"
            ];
            src = super.fetchFromGitHub {
             rev = "cc260345db57ab639db6363b2dc89072a1492832"; 
             owner = "ocaml";
             repo = "dune";
             hash = "sha256-/Cd6wvJw9eiHARwGgcmrH4HJzHwHsiBjztYUcfZX9+w=";
            };
          });
        });
      });
    in {
      devShells = {
        default = pkgs.mkShell {
          nativeBuildInputs = [pkgs.ocamlPackages.dune_3];
        };
      };

      formatter = pkgs.alejandra;
    });
}
