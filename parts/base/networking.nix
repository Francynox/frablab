{
  flake.nixosModules.base-networking =
    { config, lib, ... }:
    let
      cfg = config.frablab.base;
    in
    {
      options.frablab.base.networking.enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
        description = "Enable networking configuration";
      };

      config = lib.mkIf cfg.networking.enable {
        networking = {
          firewall.enable = lib.mkForce true;
          networkmanager.enable = true;
        };
      };
    };
}
