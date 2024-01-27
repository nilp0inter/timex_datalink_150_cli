{
  description = "A Nix-flake-based Ruby development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [ ruby_3_2 ];
        };
      });
      packages = forEachSupportedSystem ({ pkgs }: rec {
        td150 = with pkgs; let
          gems = bundlerEnv {
            name = "td150-env";
            gemdir  = ./.;
          };
        in writeShellApplication {
          name = "td150";
          runtimeInputs = [ gems gems.wrappedRuby ];
          text = ''
            exec ruby ${./timex.rb} "$@"
          '';
        };
        default = td150;
      });
    };
}
