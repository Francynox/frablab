{
  flake.nixosModules.lxc-init-script =
    {
      config,
      pkgs,
      lib,
      modulesPath,
      ...
    }:
    let
      initWipeScript = pkgs.replaceVarsWith {
        src = ./init-wipe.sh;
        isExecutable = true;
        replacements = {
          runtimeShell = pkgs.runtimeShell;
          path = lib.makeBinPath [
            pkgs.coreutils
            pkgs.findutils
          ];
          hostName = config.networking.hostName;
        };
      };

      initWrapper = pkgs.writeScript "init-wrapper" ''
        #!${pkgs.runtimeShell}
        ${initWipeScript}
        exec ${config.system.build.toplevel}/init "$@"
      '';

      installScriptBuilder = pkgs.replaceVarsWith {
        src = ./install-bootloader.sh;
        isExecutable = true;
        replacements = {
          runtimeShell = pkgs.runtimeShell;
          path = lib.makeBinPath [
            pkgs.coreutils
            pkgs.gnused
            pkgs.gnugrep
          ];
          initWipe = initWipeScript;
        };
      };
    in
    {
      system.build.init-wipe = initWipeScript;

      system.build.tarball = lib.mkForce (
        pkgs.callPackage "${modulesPath}/../lib/make-system-tarball.nix" {
          fileName = config.image.baseName;
          storeContents = [
            {
              object = config.system.build.toplevel;
              symlink = "none";
            }
          ];

          contents = [
            {
              source = initWrapper;
              target = "sbin/init";
              mode = "0755";
            }
          ];
        }
      );

      system.build.installBootLoader = lib.mkForce installScriptBuilder;
    };
}
