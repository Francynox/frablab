{ inputs, ... }:
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

      commonArgs = {
        inherit
          francynoxModulesList
          inputs
          pkgsUnstable
          pkgsStable
          ;
        self = inputs.self;
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
      };

      devShells.default = pkgs.mkShell {
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
          inputs.disko.packages.${system}.disko
        ];
      };

    };
}
