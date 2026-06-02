{
  flake.nixosModules.base-networking-dhcp =
    {
      config,
      lib,
      ...
    }:
    let
      cfg-base = config.frablab.base.networking;
      cfg = cfg-base.dhcp;
    in
    {
      options.frablab.base.networking.dhcp = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable dhcp networking configuration";
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

      config = lib.mkIf cfg.enable {
        networking = {
          networkmanager.enable = cfg.backend == "networkmanager";
          useNetworkd = cfg.backend == "networkd";
          useDHCP = false;
          useHostResolvConf = lib.mkIf (cfg.backend == "networkd") false;
        };

        systemd.network = lib.mkIf (cfg.backend == "networkd" && cfg.useDefaultDhcp) {
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
