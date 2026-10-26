{ inputs, config, ... }:
let
  topConfig = config;
in
{
  imports = [
    inputs.treefmt-nix.flakeModule
    inputs.git-hooks.flakeModule
  ];

  perSystem =
    {
      config,
      pkgs,
      system,
      lib,
      ...
    }:
    let
      inherit (topConfig) constants;

      commonArgs = {
        inherit
          inputs
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
        programs.yamlfmt.enable = true;
        programs.jsonfmt.enable = true;
        programs.just.enable = true;
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
        settings.hooks = {
          treefmt.enable = true;
          zizmor.enable = true;
          actionlint.enable = true;
          nix-flake-check = {
            enable = true;
            name = "nix-flake-check";
            entry = "bash -c 'if command -v nix >/dev/null; then nix flake check; else echo \"Skipping nix flake check in sandbox\"; fi'";
            language = "system";
            pass_filenames = false;
          };
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

        # Unit tests for the pure network lib and schema validation.
        unit-lib =
          let
            failures = import ./lib/tests/lib-test.nix {
              inherit lib;
              inherit (inputs) dns;
            };
          in
          assert lib.assertMsg (failures == [ ]) "Lib unit tests failed: ${builtins.toJSON failures}";
          pkgs.runCommand "check-unit-lib" { } "mkdir $out";

        unit-schema =
          let
            failures = import ./lib/tests/schema-test.nix { inherit lib; };
          in
          assert lib.assertMsg (failures == [ ]) "Schema unit tests failed: ${builtins.toJSON failures}";
          pkgs.runCommand "check-unit-schema" { } "mkdir $out";
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
          pkgs.nvd
          pkgs.nix-output-monitor
          pkgs.python3
          inputs.disko.packages.${system}.disko
          pkgs.deadnix
          pkgs.statix
          pkgs.ruff
          pkgs.zizmor
          pkgs.actionlint
        ];
      };
    };
}
