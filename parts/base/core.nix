{
  flake.nixosModules.base-core =
    { config, lib, ... }:
    let
      cfg = config.frablab.base;
    in
    {
      options.frablab.base = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable frablab base configuration";
        };

      };

      config = lib.mkIf cfg.enable {
        # for power management
        services = {
          power-profiles-daemon = {
            enable = true;
          };
          upower.enable = true;
          fstrim.enable = true;
          qemuGuest.enable = true;
        };

        time.timeZone = "Europe/Rome";

        # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
        system.stateVersion = "25.11";
      };
    };
}
