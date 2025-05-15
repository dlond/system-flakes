{
  description = "Multi-platform Nix Flake Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    darwin.url = "github:lnl7/nix-darwin";
    # darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... } @ inputs:
    let
      systemConfigs = system: hostname:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/${hostname}
            ./modules/system
            home-manager.nixosModuels.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPkgs = true;
              home-manager.users.dlond = import ./modules/home;
            }
          ];
        };
      
        darwinConfigs = system: hostname:
          darwin.lib.darwinSystem {
            inherit system;
            modules = [
              ./hosts/${hostname}
              ./modules/system
              home-manager.darwinModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPkgs = true;
                home-manager.users.dlond = import ./modules/home;
              }
            ];
          };
      in
      {
        nixosConfigurations = {
          linux = systemConfigs "x86_64-linux" "linux";
        };

        darwinConfigurations = {
          mbp = darwinConfigs "aarch64-darwin" "mbp";
        };
      };
}
