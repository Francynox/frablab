{
  flake.nixosModules.base-networking =
    {
      config,
      lib,
      ...
    }:
    let
      cfg-base = config.frablab.base;
      cfg = cfg-base.networking;

      dhcpNetwork = {
        networks."80-container-dhcp" = {
          matchConfig.Name =
            if cfg.interface != null then
              cfg.interface
            else
              [
                "eth*"
                "en*"
              ];
          networkConfig.DHCP = "yes";
        };
      };

      staticNetwork = {
        networks."10-default" = {
          matchConfig.Name =
            if cfg.static.interface != null then
              cfg.static.interface
            else if config.boot.isContainer then
              "eth0"
            else
              "ens18";
          networkConfig = {
            Address = cfg.static.address;
            Gateway = cfg.static.gateway;
            DNS = cfg.static.dns;
          };
        };
      };
    in
    {
      options.frablab.base.networking = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = cfg-base.enable;
          description = "Enable frablab base networking configuration";
        };
        interface = lib.mkOption {
          type = lib.types.nullOr (lib.types.either lib.types.str (lib.types.listOf lib.types.str));
          default = null;
          description = "Network interface to use for DHCP. If null, defaults to eth* and en*.";
        };
        static = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.submodule {
              options = {
                address = lib.mkOption {
                  type = lib.types.str;
                  description = "CIDR address (e.g. 10.0.80.250/24)";
                };
                gateway = lib.mkOption {
                  type = lib.types.str;
                  description = "Gateway IP address";
                };
                dns = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ "1.1.1.1" ];
                  description = "DNS servers to configure";
                };
                interface = lib.mkOption {
                  type = lib.types.nullOr (lib.types.either lib.types.str (lib.types.listOf lib.types.str));
                  default = null;
                  description = "Network interface for static network. If null, defaults to ens18 or eth0.";
                };
              };
            }
          );
          default = null;
          description = "Static IP configuration. If null, defaults to DHCP.";
        };
      };

      config = lib.mkIf cfg.enable {
        networking = {
          domain = lib.mkDefault "home.arpa";
          search = lib.mkDefault [ "home.arpa" ];
          networkmanager.enable = false;
          useNetworkd = true;
          useDHCP = false;
          useHostResolvConf = false;
        };

        systemd.network = lib.mkMerge [
          {
            enable = true;
          }
          (lib.mkIf (cfg.static == null) dhcpNetwork)
          (lib.mkIf (cfg.static != null) staticNetwork)
        ];
      };
    };
}
