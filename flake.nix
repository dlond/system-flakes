{
  description = "nix-darwin + home-manager for macOS, standalone home-manager for Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
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
      # url = "github:dlond/nvim";
      # url = "path:/Users/dlond/dev/projects/nvim";
      url = "path:/Users/dlond/dev/worktrees/nvim/nvim-maintenance-time-91";
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
    mkPkgs = import ./lib/mkPkgs.nix {
      inherit (inputs) nixpkgs;
    };
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
                packages = import ./lib/packages.nix {inherit pkgs;};
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
