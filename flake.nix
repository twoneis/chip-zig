{
  description = "Flake for chip-zig development";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, ... }@inputs: inputs.utils.lib.eachSystem [
    "x86_64-linux" "i686-linux" "aarch64-linux" "x86_64-darwin"
  ] (system: let
    pkgs = import nixpkgs {
      inherit system;
    };
    in {
      devShells.default = pkgs.mkShell {
        name = "CHIP-8";

        packages = with pkgs; [
          zig
          zls
          llvm
          SDL2
        ];

        shellHook = ''
          export PS1="[\u@chip-zig:\W]\$ "
        '';
      };
    });
}
