{
  flake.nixosModules.homelab-network =
    {
      config,
      lib,
      frablabConfig,
      ...
    }:
    let
      cfg-homelab = config.frablab.homelab;
      cfg-net = cfg-homelab.network;
      netData = config.frablab.network;
    in
    {
      imports = [
        frablabConfig.networkSchema
      ];

      options.frablab.homelab.network = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = cfg-homelab.enable;
          description = "Enable frablab homelab network configuration";
        };
        subnet = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Subnet name to look up host in for static networking. If null, defaults to DHCP.";
        };
        interface = lib.mkOption {
          type = lib.types.nullOr (lib.types.either lib.types.str (lib.types.listOf lib.types.str));
          default = null;
          description = "Network interface to use for static networking. If null, defaults to ens18 or eth0.";
        };
        dns = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ frablabConfig.network.hosts.service.bifrost.ip ];
          description = "DNS servers to configure";
        };
      };

      config = lib.mkMerge [
        {
          frablab.network = frablabConfig.network;
        }
        (lib.mkIf cfg-net.enable {
          networking = {
            domain = lib.mkOverride 900 netData.domain;
            search = lib.mkOverride 900 [ netData.domain ];
          };
        })
        (lib.mkIf (cfg-net.enable && cfg-net.subnet != null) (
          let
            subnet = netData.hosts.${cfg-net.subnet};
            host = subnet.${config.networking.hostName};
          in
          {
            systemd.network.networks."10-default" = {
              matchConfig.Name =
                if cfg-net.interface != null then
                  cfg-net.interface
                else if config.boot.isContainer then
                  "eth0"
                else
                  "ens18";
              networkConfig = {
                Address = host.address;
                Gateway = subnet.gateway.ip;
                DNS = cfg-net.dns;
              };
            };
          }
        ))
      ];
    };
}
