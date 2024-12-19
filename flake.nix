{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShell =
          with pkgs;
          (buildFHSUserEnv {
            name = "fediverse-development";
            targetPkgs =
              p: with p; [
                coreutils
                glibc
                go
                icu
                icu.dev
                libidn
                libidn.dev
                libyaml
                libyaml.dev
                nodePackages.nodejs
                nodePackages.pnpm
                nodePackages.yarn
                openssl.dev
                pkg-config
                postgresql.dev
                process-compose
                redis
                ruby
                stdenv.cc.cc
                stdenv.cc.libc
                zlib
                zlib.dev
              ];

            runScript = writeShellScript "env.sh" ''
              export LIBRARY_PATH=/usr/lib
              export INCLUDE_PATH=/usr/include
              export PKG_CONFIG_PATH=/usr/lib/pkgconfig
              export PATH=$(pwd)/bin:$PATH

              exec $(which "$(basename "$SHELL")")
            '';
          }).env;
      }
    );
}
