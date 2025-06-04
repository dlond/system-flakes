{
  description = "Minimal nix-darwin + Home Manager setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    nvim-config = {
      url = "github:dlond/nvim";
      flake = false;
    };

    catppuccin-bat = {
      url = "github:catppuccin/bat";
      flake = false;
    };

    # Optionally, add nix-darwin/home-manager as overlays for Mac, or nixosConfigurations for Linux
  };

  outputs = {
    self,
    nixpkgs,
    darwin,
    home-manager,
    nix-homebrew,
    nvim-config,
    catppuccin-bat,
    ...
  } @ inputs: let
    username = "dlond";
  in {
    darwinConfigurations.mbp = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        system = "aarch64-darwin";
        config.allowUnfree = true;
      };
      modules = [
        ./hosts/mbp/default.nix
      ];

      specialArgs = {
        inherit inputs username nvim-config catppuccin-bat home-manager nix-homebrew;
      };
    };

    homeConfigurations."${username}@mbp" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {system = "aarch64-darwin";};
      modules = [
        ./home/dlond/default.nix
      ];
      extraSpecialArgs = {
        inherit inputs username nvim-config catppuccin-bat;
      };
    };

    homeConfigurations."${username}@linux" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
      modules = [
        ./lib/shared.nix
        ./home/dlond/default.nix
        ({sharedCliPkgs, ...}: {home.packages = sharedCliPkgs;})
      ];
      extraSpecialArgs = {inherit inputs nvim-config;};
    };
  };
}
