{
  description = "A Nix flake for building and running the weron CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # Use 'self' to refer to the current flake's directory as the source.
    # This is simpler than fetching from GitHub again.
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        weronPackage = pkgs.buildGoModule {
          pname = "weron";
          # The version can be set dynamically or hard-coded.
          version = "0.3.0";

          # 'src' points to the root of your project directory.
          src = self;

          # --- THIS IS THE KEY CORRECTION ---
          # We point the build to the correct Go package containing main.go
          subPackages = [ "cmd/weron" ];

          # Nix needs a hash of the Go dependencies for a reproducible build.
          # The hash below is a placeholder. See the instructions to get the correct one.
          vendorHash = "sha256-THp5B7+NMDygdnxzsVlcR1ZdVYDDEZMp3sYLif2tLMA="; # <--- REPLACE THIS HASH

          # Statically link the binary for better portability.
          ldflags = [ "-s" "-w" ];
        };
      in
      {
        # 'packages' define what can be built or installed.
        packages = {
          default = weronPackage;
          weron = weronPackage;
        };

        # 'apps' allow running packages directly with 'nix run'.
        apps = {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/weron";
          };
        };

        # 'devShells' define development environments.
        devShells.default = pkgs.mkShell {
          name = "weron-dev-shell";

          # Tools available in the development shell.
          buildInputs = [
            weronPackage # The 'weron' command itself.
            pkgs.go      # The Go compiler and tools.
          ];

          shellHook = ''
            echo "### weron Development Shell ###"
            echo "The 'weron' executable (built from your local source) is in your PATH."
            echo "The Go toolchain is also available."
            echo ""
            echo "You can now run weron commands, for example:"
            echo "  weron --help"
          '';
        };

        # Standard formatter for Nix code. Run with 'nix fmt'.
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
