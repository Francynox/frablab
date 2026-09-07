{
  flake.nixosModules.network =
    {
      config,
      lib,
      frablabConfig,
      ...
    }:
    let
      cfg-net = config.frablab.network;
      cfg-auto-update = config.services.francynox.auto-update;
    in
    {
      imports = [
        frablabConfig.networkSchema
      ];

      options.frablab.network = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
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
          default = [ cfg-net.hosts.service.bifrost.ip ];
          description = "DNS servers to configure";
        };
      };

      config = lib.mkMerge [
        {
          frablab.network = frablabConfig.network;
        }
        (lib.mkIf cfg-auto-update.enable {
          services.francynox.auto-update.push.webhook.url =
            lib.mkDefault "http://${cfg-net.hosts.mgmt.nixos-dev.fqdn}:${toString config.services.francynox.auto-update.push-server.port}/hooks/deploy";
        })
        (lib.mkIf cfg-net.enable {
          networking = {
            domain = lib.mkOverride 900 cfg-net.domain;
            search = lib.mkOverride 900 [ cfg-net.domain ];
          };
        })
        (lib.mkIf (cfg-net.enable && cfg-net.subnet != null) (
          let
            validSubnet = builtins.hasAttr cfg-net.subnet cfg-net.subnets;
            subnet = if validSubnet then cfg-net.hosts.${cfg-net.subnet} else { };
            validHost = validSubnet && builtins.hasAttr config.networking.hostName subnet;
            host = if validHost then subnet.${config.networking.hostName} else { };
          in
          {
            assertions = [
              {
                assertion = validSubnet;
                message = "Static networking requires a valid subnet, got '${toString cfg-net.subnet}'";
              }
              {
                assertion = validHost;
                message = "Host '${config.networking.hostName}' not found in subnet '${cfg-net.subnet}'";
              }
            ];

            frablab.base.networking.static = lib.mkIf (validSubnet && validHost) {
              inherit (host) address;
              gateway = subnet.gateway.ip;
              inherit (cfg-net) dns;
              inherit (cfg-net) interface;
            };
          }
        ))
      ];
    };
}
