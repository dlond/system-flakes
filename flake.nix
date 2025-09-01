{
  description = "nix-darwin + home-manager for macOS, standalone home-manager for Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };

    nvim-config = {
      url = "github:dlond/nvim";
      flake = false;
    };

    catppuccin-bat = {
      url = "github:catppuccin/bat";
      flake = false;
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {self, ...}: let
    username = "dlond";
    systems = {
      darwin = "aarch64-darwin";
      linux = "aarch64-linux";
      linux_x86 = "x86_64-linux";
    };
    mkPkgs = import ./lib/mkPkgs.nix {inherit (inputs) nixpkgs;};
  in {
    #### macOS full-system (nix-darwin + HM)
    darwinConfigurations.mbp = let
      system = systems.darwin;
      pkgs = mkPkgs system;
    in
      inputs.nix-darwin.lib.darwinSystem {
        inherit system pkgs;

        ## Main modules
        modules = [
          inputs.sops-nix.darwinModules.sops
          inputs.nix-homebrew.darwinModules.nix-homebrew
          ./hosts/mbp/default.nix
          inputs.home-manager.darwinModules.home-manager

          ## Per-host inline module
          {
            users.users.${username}.home = "/Users/${username}";

            ## Home-Manager wiring
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;

              ## Extra args for Home-Manager
              extraSpecialArgs = {
                inherit pkgs;
                inherit (inputs) sops-nix nvim-config catppuccin-bat;
                shared = import ./lib/shared.nix {
                  inherit pkgs;
                  lib = pkgs.lib;
                };
              };
              users.${username} = import ./home/users/${username};
            };
          }
        ];

        ## Extra args for nix-darwin modules
        specialArgs = {
          inherit pkgs username;
          inherit (self) inputs;
        };
      };

    #### Linux standalone Home-Manager
    homeConfigurations."${username}@linux" = let
      system = systems.linux;
      pkgs = mkPkgs system;
    in
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home/users/${username}
        ];
        extraSpecialArgs = {
          inherit (inputs) sops-nix nvim-config catppuccin-bat;
          shared = import ./lib/shared.nix {
            inherit pkgs;
            lib = pkgs.lib;
          };
        };
      };
  };
}
