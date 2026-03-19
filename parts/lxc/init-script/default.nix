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
          inherit (pkgs) runtimeShell;
          path = lib.makeBinPath [
            pkgs.coreutils
            pkgs.findutils
          ];
          inherit (config.networking) hostName;
        };
      };

      initWrapper = pkgs.writeScript "init-wrapper" ''
        #!${pkgs.runtimeShell}
        ${lib.optionalString config.frablab.lxc.init-script.wipeRoot "${initWipeScript}"}
        exec ${config.system.build.toplevel}/init "$@"
      '';

      installScriptBuilder = pkgs.replaceVarsWith {
        src = ./install-bootloader.sh;
        isExecutable = true;
        replacements = {
          inherit (pkgs) runtimeShell;
          path = lib.makeBinPath [
            pkgs.coreutils
            pkgs.gnused
            pkgs.gnugrep
          ];
          initWipe = if config.frablab.lxc.init-script.wipeRoot then "${initWipeScript}" else "true";
        };
      };
    in
    {
      options.frablab.lxc.init-script = {
        wipeRoot = lib.mkOption {
          type = lib.types.bool;
          default = config.frablab.base.persistence.enable or false;
          description = "Whether to wipe the root filesystem on boot for LXC containers.";
        };
      };

      config = {
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
    };
}
