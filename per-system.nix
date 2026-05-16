{ inputs, config, ... }:
let
  topConfig = config;
in
{
  perSystem =
    {
      config,
      pkgs,
      system,
      lib,
      ...
    }:
    let
      francynoxModulesList = lib.attrValues inputs.nur-francynox.nixosModules;

      pkgsUnstable = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      pkgsStable = import inputs.nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };

      inherit (topConfig) constants;

      commonArgs = {
        inherit
          francynoxModulesList
          inputs
          pkgsUnstable
          pkgsStable
          constants
          ;
        inherit (inputs) self;
      };
    in
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ inputs.nur-francynox.overlays.namespace ];
        config.allowUnfree = true;
      };

      _module.args.commonArgs = commonArgs;

      treefmt = {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
        programs.deadnix.enable = true;
        programs.statix.enable = true;
        programs.ruff = {
          check = true;
          format = true;
        };
      };

      pre-commit = {
        check.enable = true;
        settings.hooks.treefmt.enable = true;
        settings.hooks.nix-flake-check = {
          enable = true;
          name = "nix-flake-check";
          entry = "bash -c 'if command -v nix >/dev/null; then nix flake check; else echo \"Skipping nix flake check in sandbox\"; fi'";
          language = "system";
          pass_filenames = false;
        };
      };

      checks = {
        conventions =
          pkgs.runCommand "check-conventions"
            {
              nativeBuildInputs = [ pkgs.python3 ];
              src = inputs.self;
            }
            ''
              python3 $src/scripts/check_conventions.py $src/parts
              mkdir $out
            '';

        network-data = pkgs.runCommand "check-network-data" { } ''
          echo '${builtins.toJSON inputs.self.nixosConfigurations.mimir.config.frablab.network}' > $out
        '';
      };

      devShells.default = pkgs.mkShell {
        shellHook = ''
          ${config.pre-commit.installationScript}
        '';

        packages = [
          config.treefmt.build.wrapper
          pkgs.just
          pkgs.sops
          pkgs.ssh-to-age
          pkgs.git
          pkgs.age
          pkgs.nix
          pkgs.home-manager
          pkgs.nvd
          pkgs.nix-output-monitor
          pkgs.python3
          inputs.disko.packages.${system}.disko
          pkgs.deadnix
          pkgs.statix
          pkgs.ruff
        ];
      };

    };
}
