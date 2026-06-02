{
  flake.nixosModules.base-networking-static =
    {
      config,
      lib,
      ...
    }:
    let
      cfg-base = config.frablab.base.networking;
      cfg = cfg-base.static;
    in
    {
      options.frablab.base.networking.static = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable static networking configuration";
        };
        subnet = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Subnet name to look up host in.";
        };
        interface = lib.mkOption {
          type = lib.types.str;
          default = if config.boot.isContainer then "eth0" else "ens18";
          description = "Network interface name";
        };
        dns = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ config.frablab.network.hosts.service.bifrost.ip ];
          description = "DNS servers";
        };
        disableStubResolver = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Disable stub resolver";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.subnet != "" && builtins.hasAttr cfg.subnet config.frablab.network.subnets;
            message = "Static networking requires a valid subnet, got '${cfg.subnet}'";
          }
        ];

        networking = {
          networkmanager.enable = false;
          useNetworkd = true;
          useDHCP = false;
          useHostResolvConf = false;
        };

        systemd.network =
          let
            subnet = config.frablab.network.hosts.${cfg.subnet};
            host = subnet.${config.networking.hostName};
          in
          {
            networks."10-default" = {
              matchConfig.Name = cfg.interface;
              networkConfig = {
                Address = host.address;
                Gateway = subnet.gateway.ip;
                DNS = cfg.dns;
              };
            };
          };

        services.resolved = lib.mkIf cfg.disableStubResolver {
          enable = true;
          settings = {
            Resolve = {
              DNSStubListener = "no";
            };
          };
        };
      };
    };
}
