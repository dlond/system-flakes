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
      # Add "aarch64-linux", "x86_64-linux" etc if needed
      supportedSystems = [ "aarch64-darwin" "x86_64-darwin" ];

      # Helper function to generate nixpkgs instances for each system
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      importModules = import ./lib/import-modules.nix;

    in
    {
      # Overlays can be defined in overlays/ directory
      # overlays.default = import ./overlays;

      # NixOS configurations (add later for RPi, Jetson, Cloud VM)
      # nixosConfigurations.rpi = nixpkgs.lib.nixosSystem {
      #   system = "aarch64-linux";
      #   specialArgs = { inherit inputs; } # Pass down inputs
      #   modules = [ ./hosts/rpi/default.nix ];
      # };

      # Darwin configurations
      darwinConfigurations.mbp = nix-darwin.lib.darwinSystem (
        let
          system = "aarch64-darwin";
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in {
          inherit system;

          specialArgs = { inherit inputs; };

          modules = [
            ./hosts/mbp/default.nix
            inputs.home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "bak";

              home-manager.extraSpecialArgs = {
                inherit pkgs inputs;
              };

              home-manager.users.dlond = import ./home/users/dlond;
            }
          ];
        }
      );

      # Home Manager configurations (if managing separately)
      # homeConfigurations."your-username@mbp" = home-manager.lib.homeManagerConfiguration {
      #   pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      #   extraSpecialArgs = { inherit inputs; };
      #   modules = [ ./home/users/dlond/default.nix ];
      # };
    };
}

