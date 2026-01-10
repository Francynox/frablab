{
  flake.nixosModules.base-auto-update =
    { config, lib, ... }:
    let
      cfg = config.frablab.base;
    in
    {
      options.frablab.base.auto-update = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = cfg.enable;
          description = "Enable auto-update";
        };

        auto-reboot.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable auto-reboot";
        };
      };

      config = lib.mkIf cfg.auto-update.enable {
        system.autoUpgrade = {
          enable = true;
          dates = "*-*-* 02:00:00";
          randomizedDelaySec = "1h";
          flake = "github:Francynox/frablab";
          allowReboot = cfg.auto-update.auto-reboot.enable && !config.boot.isContainer;
        };
      };
    };
}
