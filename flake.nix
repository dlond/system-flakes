{
  description = "My multi-system Nix configuration flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Home Manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Darwin Inputs
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    mac-app-util.url = "github:hraban/mac-app-util";

    # neovim config
    nvim-config = {
      url = "github:dlond/nvim";
      flake = false;
    };

    # Linux Inputs
    # nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, nvim-config, ... }:
    let
      lib = nixpkgs.lib // {
        importModules = import ./lib/import-modules.nix { lib = nixpkgs.lib; };
        hm = inputs.home-manager.lib.hm;
      };
    in {
      # Overlays can be defined in overlays/ directory
      # overlays.default = import ./overlays;

      # NixOS configurations e.g.
      # nixosConfigurations.rpi = nixpkgs.lib.nixosSystem {
      #   system = "aarch64-linux";
      #   specialArgs = { inherit inputs; } # Pass down inputs
      #   modules = [ ./hosts/rpi/default.nix ];
      # };

      # Darwin configurations
      darwinConfigurations."mbp" = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";

          modules = [
            ./hosts/mbp/default.nix
            inputs.home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = false;
                backupFileExtension = "bak";

                users.dlond = ./home/users/dlond;
              };
            }
          ];

          specialArgs = {
            inherit inputs;
            nvim-config = inputs.nvim-config;
            lib = lib;
          };
        };
      };

      # Home Manager configurations (if managing separately)
      # homeConfigurations."your-username@mbp" = home-manager.lib.homeManagerConfiguration {
      #   pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      #   extraSpecialArgs = { inherit inputs; };
      #   modules = [ ./home/users/dlond/default.nix ];
      # };
}

