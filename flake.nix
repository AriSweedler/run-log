# run-log: run_log (a command's stdout and stderr captured byte for byte, each on its own pty,
# into a capture directory an agent reads back), its capture engine, irun and strip-ansi.
{
  description = "run_log: capture a command's output into a directory an agent can read";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    ari-zshlib = { url = "github:AriSweedler/ari-zshlib"; inputs.nixpkgs.follows = "nixpkgs"; };
  };
  outputs = { self, nixpkgs, ari-zshlib }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      each = f: nixpkgs.lib.genAttrs systems (s: f nixpkgs.legacyPackages.${s} s);
    in
    {
      packages = each (pkgs: system: {
        default = pkgs.callPackage ./package.nix { zshlib = ari-zshlib.packages.${system}.default; };
      });
    };
}
