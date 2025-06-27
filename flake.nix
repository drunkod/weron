{
  description = "A Nix flake for building and running the weron CLI and its tutorials";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        weronPackage = pkgs.buildGoModule {
          pname = "weron";
          version = "0.3.0";
          src = self;
          subPackages = [ "cmd/weron" ];

          # Nix needs a hash of the Go dependencies for a reproducible build.
          # The hash below is a placeholder. See the instructions to get the correct one.
          vendorHash = "sha256-THp5B7+NMDygdnxzsVlcR1ZdVYDDEZMp3sYLif2tLMA="; # <--- REPLACE THIS HASH

          # Statically link the binary for better portability.
          ldflags = [ "-s" "-w" ];
        };

        # Helper to create a simple app that runs a weron subcommand
        mkWeronApp = name: extraFlags: pkgs.writeShellScriptBin name ''
          #!${pkgs.stdenv.shell}
          echo "Running: weron ${extraFlags} $@"
          exec ${weronPackage}/bin/weron ${extraFlags} "$@"
        '';

      in
      {
        packages = {
          default = weronPackage;
          weron = weronPackage;
        };

        apps = {
          default = {
            type = "app";
            program = "${weronPackage}/bin/weron";
          };

          signaler = {
            type = "app";
            program = "${pkgs.writeShellScriptBin "run-signaler" ''
              #!${pkgs.stdenv.shell}
              echo "### Starting a local weron signaler ###"
              echo "This starts a simple, in-memory signaling server for testing."
              echo "It will be available at ws://localhost:1337"
              echo ""
              echo "For production, you should set up an external PostgreSQL and Redis"
              echo "and run the signaler with --postgres-url and --redis-url flags."
              echo "You must also provide an API password for the manager."
              echo ""
              echo "Example for testing with a password:"
              echo "  nix run .#signaler -- --api-password 'myapipassword'"
              echo "--------------------------------------------------------"
              exec ${weronPackage}/bin/weron signaler "$@"
            ''}/bin/run-signaler";
          };

          manager-list = {
            type = "app";
            program = "${pkgs.writeShellScriptBin "run-manager-list" ''
              #!${pkgs.stdenv.shell}
              echo "### Listing communities ###"
              echo "Note: This requires a running signaler. Set env vars if needed:"
              echo "  export WERON_RADDR='http://localhost:1337/'"
              echo "  export API_PASSWORD='myapipassword'"
              echo "--------------------------------------------------------"
              exec ${weronPackage}/bin/weron manager list "$@"
            ''}/bin/run-manager-list";
          };

          # --- CORRECTED SECTION ---
          # All apps now have the correct { type = "app"; program = "..."; } structure.
          manager-create = {
            type = "app";
            program = "${mkWeronApp "manager-create" "manager create"}/bin/manager-create";
          };
          manager-delete = {
            type = "app";
            program = "${mkWeronApp "manager-delete" "manager delete"}/bin/manager-delete";
          };
          # --- END CORRECTED SECTION ---

          chat = {
            type = "app";
            program = "${pkgs.writeShellScriptBin "run-chat" ''
              #!${pkgs.stdenv.shell}
              echo "### Starting weron chat ###"
              echo "Example to connect to the public signaler:"
              echo '  nix run .#chat -- --community mycommunity --password mypassword --key mykey --names user1'
              echo ""
              echo "To connect to a local signaler, first run 'nix run .#signaler' in another terminal, then:"
              echo '  nix run .#chat -- --raddr ws://localhost:1337 --community mycommunity --password mypassword --key mykey --names user1'
              echo "--------------------------------------------------------"
              exec ${weronPackage}/bin/weron chat "$@"
            ''}/bin/run-chat";
          };

          # --- CORRECTED SECTION ---
          latency-server = {
            type = "app";
            program = "${mkWeronApp "latency-server" "utility latency --server"}/bin/latency-server";
          };
          latency-client = {
            type = "app";
            program = "${mkWeronApp "latency-client" "utility latency"}/bin/latency-client";
          };
          throughput-server = {
            type = "app";
            program = "${mkWeronApp "throughput-server" "utility throughput --server"}/bin/throughput-server";
          };
          throughput-client = {
            type = "app";
            program = "${mkWeronApp "throughput-client" "utility throughput"}/bin/throughput-client";
          };
          # --- END CORRECTED SECTION ---

          vpn-ip = {
            type = "app";
            program = "${pkgs.writeShellScriptBin "run-vpn-ip" ''
              #!${pkgs.stdenv.shell}
              echo "### Starting weron IP VPN (Layer 3) ###"
              if [ "$(id -u)" -ne 0 ]; then
                  echo ""
                  echo "!!!!!!!!!!!!!!!!!! PERMISSION ERROR !!!!!!!!!!!!!!!!!! "
                  echo "This command requires network administrator privileges to create a TUN device."
                  echo "The app will now exit. To run it correctly, please use 'sudo':"
                  echo ""
                  echo "  sudo nix run .#vpn-ip -- [YOUR-VPN-FLAGS]"
                  echo ""
                  echo "Example:"
                  echo "  sudo nix run .#vpn-ip -- --community mycommunity --password mypassword --key mykey --ips 10.0.0.1/24"
                  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                  exit 1
              fi
              exec ${weronPackage}/bin/weron vpn ip "$@"
            ''}/bin/run-vpn-ip";
          };
          vpn-ethernet = {
            type = "app";
            program = "${pkgs.writeShellScriptBin "run-vpn-ethernet" ''
              #!${pkgs.stdenv.shell}
              echo "### Starting weron Ethernet VPN (Layer 2) ###"
              if [ "$(id -u)" -ne 0 ]; then
                  echo ""
                  echo "!!!!!!!!!!!!!!!!!! PERMISSION ERROR !!!!!!!!!!!!!!!!!! "
                  echo "This command requires network administrator privileges to create a TAP device."
                  echo "The app will now exit. To run it correctly, please use 'sudo':"
                  echo ""
                  echo "  sudo nix run .#vpn-ethernet -- [YOUR-VPN-FLAGS]"
                  echo ""
                  echo "Example:"
                  echo "  sudo nix run .#vpn-ethernet -- --community mycommunity --password mypassword --key mykey"
                  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                  exit 1
              fi
              exec ${weronPackage}/bin/weron vpn ethernet "$@"
            ''}/bin/run-vpn-ethernet";
          };
        };

        devShells.default = pkgs.mkShell {
          name = "weron-dev-shell";
          buildInputs = [ weronPackage pkgs.go ];
          shellHook = ''
            echo "### weron Development Shell ###"
            echo "The 'weron' executable (from your local source) is in your PATH."
            echo ""
            echo "--- IMPORTANT: For VPN Usage ---"
            echo "To use 'weron vpn ...', the binary needs network admin capabilities."
            echo "If you are not in a pre-configured container, grant them by running:"
            echo "  sudo setcap cap_net_admin+ep $(which weron)"
            echo "--------------------------------"
          '';
        };

        formatter = pkgs.nixpkgs-fmt;
      }
    );
}