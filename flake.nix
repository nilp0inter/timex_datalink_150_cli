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
      packages = forEachSupportedSystem ({ pkgs }: let
        timex-original-software = pkgs.fetchurl {
          url = "https://assets.timex.com/downloads/TDL21D.EXE";
          hash = "sha256-8w5wNBROp3nH743NTHGc/+9ERchzQb6Y7uYyqlAEhZY=";
        };
        timex-assets = name: pattern: pkgs.stdenv.mkDerivation {
          name = name;
          src = timex-original-software;
          buildInputs = [ pkgs.p7zip ];
          phases = [ "installPhase" ];
          installPhase = ''
            mkdir -p "$out"
            7z e $src SETUP.EXE -o.
            7z e ./SETUP.EXE -o"$out" -r -y "${pattern}"
          '';
        };
      in rec {
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
        sound-themes = timex-assets "sound-themes" "*.SPC";
        wrist-apps = timex-assets "wrist-apps" "*.ZAP";
        default = td150;
      });
    };
}
