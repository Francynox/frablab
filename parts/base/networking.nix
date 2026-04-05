{
  flake.nixosModules.base-networking =
    {
      config,
      lib,
      constants,
      ...
    }:
    let
      cfg-base = config.frablab.base;
      cfg = cfg-base.networking;
    in
    {
      options.frablab.base.networking = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = cfg-base.enable;
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
        search = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ constants.domain ];
          description = "Search domains to use";
        };
        domain = lib.mkOption {
          type = lib.types.str;
          default = constants.domain;
          description = "Local domain name";
        };
      };

      config = lib.mkIf cfg.enable {
        networking = {
          networkmanager.enable = cfg.backend == "networkmanager";
          useNetworkd = cfg.backend == "networkd";
          useDHCP = false;
          useHostResolvConf = lib.mkIf (cfg.backend == "networkd") false;
          inherit (cfg) search;
          inherit (cfg) domain;
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
