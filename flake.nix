{
  description = "My nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    mac-app-util.url = "github:hraban/mac-app-util";
  };

  outputs = inputs@{
    self,
    nix-darwin,
    nixpkgs,
    nix-homebrew,
    mac-app-util,
    }:
    let
      configuration = { pkgs, ... }: {
	nixpkgs.config.allowUnfree = true;

	# List packages installed in system profile. To search by name, run:
	# $ nix-env -qaP | grep wget
	environment.systemPackages =
	  [ 
	    pkgs.git
	    pkgs.neovim
	    pkgs.tmux
	    pkgs.stow
	    pkgs.fzf
	    pkgs.zoxide
	    pkgs.bat
	    pkgs.ripgrep
	    pkgs.wget
	    pkgs.oh-my-posh
	    pkgs.go
	    pkgs.rustup
	    pkgs.nodejs

	    pkgs.gnupg
	    pkgs.tor

	    pkgs.raycast
	    pkgs.whatsapp-for-mac
	    pkgs.ollama
	  ];

	homebrew = {
	  enable = true;
	  taps = [];
	  brews = [
	    "mas"
	  ];
	  casks = [
	    "ghostty"
	    "1password"
	    "vlc"
	  ];
	  masApps = {
	    "AdGuard" = 1440147259;
	    "Messenger" = 1480068668;
	    "Logic Pro" = 634148309;
	    # "MainStage" = 634159523;
	    "Final Cut Pro" = 424389933;
	    # "Motion" = 434290957;
	    # "Compressor" = 424390742;
	    "Numbers" = 409203825;
	  };
	  onActivation.cleanup = "zap";
	  onActivation.autoUpdate = true;
	  onActivation.upgrade = true;
	};

	fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

	# Can't get this shit to work (didn't really try!)
	# system.defaults = {
	#   NSGlobalDomain.AppleInterfaceStyle = "Dark";
	#   finder.FXPreferredViewStyle = "clmv";
	#   loginwindow.GuestEnabled = false;
	#   trackpad.Clicking = true;
	#   dock.autohide = false;
	# };

	# Use touchID for sudo
	security.pam.services.sudo_local.touchIdAuth = true;

	# Necessary for using flakes on this system.
	nix.settings.experimental-features = "nix-command flakes";

	# Enable alternative shell support in nix-darwin.
	# programs.fish.enable = true;

	# Set Git commit hash for darwin-version.
	system.configurationRevision = self.rev or self.dirtyRev or null;

	# Used for backwards compatibility, please read the changelog before changing.
	# $ darwin-rebuild changelog
	system.stateVersion = 6;

	# The platform the configuration will be used on.
	nixpkgs.hostPlatform = "aarch64-darwin";
      };
    in
      {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#mbp
      darwinConfigurations."mbp" = nix-darwin.lib.darwinSystem {
	modules = [
	  configuration
	  nix-homebrew.darwinModules.nix-homebrew {
	    nix-homebrew = {
	      enable = true;
	      enableRosetta = true;
	      user = "dlond";
	    };
	  }
	  mac-app-util.darwinModules.default
	];
      };
    };
}
