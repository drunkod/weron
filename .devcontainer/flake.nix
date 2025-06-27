{
  # A description for your flake
  description = "A development environment for my project";

  # The inputs for this flake, primarily the Nix packages collection
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  # The outputs of this flake
  outputs = { self, nixpkgs }:
    let
      # Systems to support
      systems = [
        "x86_64-linux"
        "aarch64-linux" # For ARM-based systems, including Apple Silicon Macs
      ];

      # Helper function to generate a dev shell for a given system
      forAllSystems = nixpkgs.lib.genAttrs systems;

    in
    {
      # The development shell is defined here
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            # This message will be displayed when the shell starts
            motd = ''
              Welcome to the NixOS Dev Shell!
              Provided packages: git, gcc, go, nodejs
            '';

            # The list of packages to make available in the shell
            packages = with pkgs; [
              # Essential development tools
              git
              gcc
              gnumake

              # Language-specific tools (add what you need)
              go
              nodejs_22 # Use a specific version

              # Useful utilities
              ripgrep
              fd
            ];

            # You can also set environment variables here
            shellHook = ''
              export MY_PROJECT_VAR="Hello from Nix!"
            '';
          };
        }
      );
    };
}