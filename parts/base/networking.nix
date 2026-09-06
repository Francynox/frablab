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

      # --- DHCP Profile (used when subnet is null) ---
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

      # --- Static Profile (used when subnet is declared) ---
      staticNetwork =
        let
          subnet = config.frablab.network.hosts.${cfg.subnet};
          host = subnet.${config.networking.hostName};
        in
        {
          networks."10-default" = {
            matchConfig.Name =
              if cfg.interface != null then
                cfg.interface
              else if config.boot.isContainer then
                "eth0"
              else
                "ens18";
            networkConfig = {
              Address = host.address;
              Gateway = subnet.gateway.ip;
              DNS = cfg.dns;
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
        subnet = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Subnet name to look up host in for static networking. If null, defaults to DHCP.";
        };
        interface = lib.mkOption {
          type = lib.types.nullOr (lib.types.either lib.types.str (lib.types.listOf lib.types.str));
          default = null;
          description = "Network interface to use for networking. If null, defaults to ens18 or eth0.";
        };
        dns = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ config.frablab.network.hosts.service.bifrost.ip ];
          description = "DNS servers to configure";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.subnet == null || builtins.hasAttr cfg.subnet config.frablab.network.subnets;
            message = "Static networking requires a valid subnet, got '${toString cfg.subnet}'";
          }
        ];

        networking = {
          domain = lib.mkDefault config.frablab.network.domain;
          search = lib.mkDefault [ config.frablab.network.domain ];
          networkmanager.enable = false;
          useNetworkd = true;
          useDHCP = false;
          useHostResolvConf = false;
        };

        systemd.network = lib.mkMerge [
          {
            enable = true;
          }
          (lib.mkIf (cfg.subnet == null) dhcpNetwork)
          (lib.mkIf (cfg.subnet != null) staticNetwork)
        ];
      };
    };
}
