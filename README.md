## Updating Neovim & Flake Inputs

This flake manages the system configuration and pulls in the Neovim configuration from a separate repository ([dlond/nvim](https://github.com/dlond/nvim)) via a flake input (`nvim-config`).

This workflow assumes you are updating both your Neovim configuration and your general flake inputs (like `nixpkgs`, `home-manager`, etc.) at the same time.

1.  **Modify Neovim Config (If Applicable):**
    * Make any desired changes within your local clone of the `dlond/nvim` repository.
    * Commit and push these changes to the `dlond/nvim` repository on GitHub.
        ```bash
        # Navigate to your local nvim config repo
        cd path/to/your/local/dlond/nvim 
        
        # Stage, commit, and push
        git add .
        git commit -m "feat(nvim): description of changes" 
        git push origin main # Or your default branch
        ```

2.  **Update All Flake Inputs & Lock File:**
    * Navigate back to your main system configuration repository (`~/system-flakes`).
    * Run `nix flake update`. This command fetches the latest versions for *all* inputs defined in your `flake.nix` (including `nixpkgs`, `home-manager`, and `nvim-config` pointing to the commit you just pushed) and updates the `flake.lock` file accordingly.
        ```bash
        cd ~/system-flakes 
        nix flake update
        ```

3.  **Rebuild System Configuration:**
    * Apply the changes by rebuilding your Nix Darwin system. This fetches the updated sources based on the new lock file and links the latest Neovim config into `~/.config/nvim`.
        ```bash
        darwin-rebuild switch --flake .#mbp 
        ```
    * *(Replace `mbp` with your actual host name if different)*

4.  **Commit & Push Updated Lock File:**
    * Commit the modified `flake.lock` file to your `system-flakes` repository to record the updated dependencies.
        ```bash
        git add flake.lock
        git commit -m "feat: update flake inputs (including nvim)" # Updated commit message
        git push
        ```

Your system will now use the updated Neovim configuration and the latest versions of your other flake inputs.
