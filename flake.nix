{
  description = "nix-darwin + home-manager for macOS, standalone home-manager for Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      # url = "github:nix-community/home-manager";
      url = "path:/Users/dlond/dev/projects/home-manager";
      # inputs.nixpkgs.follows = "nixpkgs";
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

    mkPkg = {
      nixpkgs,
      overlays ? [],
      config ? {allowUnfree = true;},
    }: system:
      import nixpkgs {
        inherit system config overlays;
      };

    mkSystemConfig = system: let
      pkgs = mkPkg {inherit (inputs) nixpkgs;} system;
      packages = import ./lib/packages.nix {inherit pkgs;};
    in {
      inherit pkgs packages;
    };
  in {
    #### macOS full-system (nix-darwin + HM)
    darwinConfigurations.mbp = let
      sysConfig = mkSystemConfig systems.darwin;
    in
      inputs.nix-darwin.lib.darwinSystem {
        inherit (sysConfig) pkgs;

        modules = [
          inputs.sops-nix.darwinModules.sops
          inputs.nix-homebrew.darwinModules.nix-homebrew
          ./hosts/mbp/default.nix
          {
            users.users.${username}.home = "/Users/${username}";
            nixpkgs.config = {
              extraBuildFlags = ["-mmacosx-version-min=26.0"];
              extraConfigureFlags = ["-mmacosx-version-min=26.0"];
            };
          }
        ];
        specialArgs = {
          inherit (sysConfig) pkgs packages;
          inherit username inputs;
        };
      };

    homeConfigurations."${username}@mbp" = let
      sysConfig = mkSystemConfig systems.darwin;
      minimal = "";
    in
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit (sysConfig) pkgs;
        modules = [./home/users/${username}];
        extraSpecialArgs = {
          inherit (inputs) nix nvim-config catppuccin-bat;
          inherit (sysConfig) pkgs packages;
          inherit minimal;
        };
      };

    #### Linux standalone Home-Manager
    homeConfigurations."${username}@linux" = let
      system = systems.linux;
      pkgs = mkPkg {inherit (inputs) nixpkgs;} system;
    in
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home/users/${username}
        ];
        extraSpecialArgs = {
          inherit pkgs;
          inherit (inputs) sops-nix nvim-config catppuccin-bat;
          packages = import ./lib/packages.nix {inherit pkgs;};
        };
      };

    #### Development Templates
    templates = {
      python = {
        path = ./templates/python;
        description = "Python development environment with uv for dependency management";
      };
      cpp = {
        path = ./templates/cpp;
        description = "C++ development environment with Conan and CMake presets";
      };
      python-cpp = {
        path = ./templates/python-cpp;
        description = "Combined Python + C++ environment for bindings and mixed projects";
      };
      ocaml = {
        path = ./templates/ocaml;
        description = "OCaml learning environment with Jane Street Core/Async essentials";
      };
      python-jax = {
        path = ./templates/python-jax;
        description = "Python + JAX ML environment with LaTeX for quantitative research";
      };
      cpp-lowlat = {
        path = ./templates/cpp-lowlat;
        description = "C++ low-latency environment for high-performance systems development";
      };
    };
  };
}
