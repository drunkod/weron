{
  description = "A Nix flake for running the weron CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    weron-src = {
      url = "github:pojntfx/weron/v0.3.0";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, weron-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        weronPackage = pkgs.buildGoModule {
          pname = "weron";
          version = "0.3.0";

          src = weron-src;

          # The main package for the weron CLI is in the root of the repository.
          subPackages = [ "." ];

          # To get this hash, first use a placeholder like this:
          # vendorHash = pkgs.lib.fakeSha256;
          # Then, run 'nix build .#weron'. The build will fail and print the correct hash.
          # Replace the placeholder with the correct hash.
          vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

          # Statically link the binary for portability on systems like Alpine.
          ldflags = [ "-s" "-w" ];
        };
      in
      {
        packages = {
          # The default package is the weron binary.
          default = weronPackage;
          weron = weronPackage;
        };

        apps = {
          # The default app runs the weron command.
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/weron";
          };
        };

        devShells.default = pkgs.mkShell {
          name = "weron-dev-shell";

          buildInputs = [
            weronPackage
            pkgs.go
          ];

          shellHook = ''
            echo "### weron Development Shell ###"
            echo "The 'weron' executable (built from local sources) is in your PATH."
            echo "The Go toolchain is also available."
            echo ""
            echo "You can now run weron commands, for example:"
            echo "  weron --help"
          '';
        };

        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
