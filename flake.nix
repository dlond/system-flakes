{
  description = "Minimal working darwin flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:lnl7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      darwinConfigurations.mbp = nix-darwin.lib.darwinSystem {
        inherit system;

        modules = [
          # This defines the user account — needed for `home-manager.users.dlond`
          {
            users.users.dlond = {
              name = "dlond";
              home = "/Users/dlond";
              shell = pkgs.zsh;
            };
          }

          # Home Manager module
          home-manager.darwinModules.home-manager

          # Home Manager config
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = false;

            home-manager.users.dlond = import ./home/users/dlond;
          }
        ];

        specialArgs = {
          inherit pkgs;
        };
      };
    };
}

