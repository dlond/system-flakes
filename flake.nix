{
  description = "Minimal working darwin flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:lnl7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, ... }:
    let
      system = "aarch64-darwin";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      importModules = import ./lib/import-modules.nix {
        inherit pkgs inputs;
        lib = nixpkgs.lib;
      };

      lib = nixpkgs.lib // {
        hm = home-manager.lib.hm;
      };

    in {
      darwinConfigurations.mbp = nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = {
          inherit inputs pkgs lib importModules;
        };

        modules = [
          ./hosts/mbp/default.nix
          ./modules/darwin/base.nix

          # Home Manager module
          home-manager.darwinModules.home-manager

          # Home Manager config
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = false;

            home-manager.users.dlond = import ./home/users/dlond;
          }
        ];
      };
    };
}

