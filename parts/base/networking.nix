{
  flake.nixosModules.base-networking =
    { config, lib, ... }:
    let
      cfg = config.frablab.base;
    in
    {
      options.frablab.base.networking = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = cfg.enable;
          description = "Enable networking configuration";
        };
        backend = lib.mkOption {
          type = lib.types.enum [
            "networkd"
            "networkmanager"
          ];
          default = "networkd";
          description = "Networking backend to use";
        };
        useDefaultDhcp = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable default DHCP configuration for eth* and en* interfaces";
        };
      };

      config = lib.mkIf cfg.networking.enable {
        networking = {
          firewall.enable = lib.mkForce true;
          networkmanager.enable = cfg.networking.backend == "networkmanager";
          useNetworkd = cfg.networking.backend == "networkd";
          useDHCP = false;
          useHostResolvConf = lib.mkIf (cfg.networking.backend == "networkd") false;
        };

        systemd.network = lib.mkIf (cfg.networking.backend == "networkd" && cfg.networking.useDefaultDhcp) {
          enable = true;
          networks."80-container-dhcp" = {
            matchConfig.Name = [
              "eth*"
              "en*"
            ];
            networkConfig.DHCP = "yes";
          };
        };
      };
    };
}
