{
  description = "Multi-platform Nix Flake Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    darwin.url = "github:lnl7/nix-darwin/master";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nvim-config.url = "github:dlond/nvim";
    nvim-config.flake = false;
  };

  outputs = { self, nixpkgs, darwin, home-manager, nvim-config, ... } @ inputs:
  {
      darwinConfigurations = {
          mbp = darwin.lib.darwinSystem {
            system = "aarch64-darwin";
        
            modules = [
              ./hosts/mbp
              ./modules/system
              home-manager.darwinModules.home-manager

              ({ config, ... }:
                let
                  pkgs = import nixpkgs {
                    system = "aarch64-darwin";
                    config.allowUnfree = true;
                  };
                in  {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.users.dlond = import ./modules/home {
                    inherit inputs pkgs;
                  };
               })
            ];
          };
        };

        nixosConfigurations = {
          linux = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";

            modules = [
              ./hosts/linux
              ./modules/system
              home-manager.nixosModules.home-manager
              
              ({ config, ... }:
                let
                  pkgs = import nixpkgs {
                    system = "x86_64-linux";
                    cofig.allowUnfree = true;
                  };
                in {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.users.dlond = import ./modules/home {
                    inherit pkgs inputs;
                  };
                }
              )
            ];
          };
        };
  };
}
