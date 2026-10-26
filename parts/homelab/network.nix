{ self, ... }:
{
  flake.nixosModules.homelab-network =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.frablab.homelab.network;
      clusterNet = config.frablab.network;

      # Auto-detect interface name: explicit override -> container eth0 -> VM ens18
      interfaceName =
        if cfg.interface != null then
          cfg.interface
        else if config.boot.isContainer then
          "eth0"
        else
          "ens18";

      # Look up this host's assigned IP and gateway from the cluster topology
      subnetData = clusterNet.hosts.${cfg.subnet} or null;
      hostData = subnetData.${config.networking.hostName} or null;
    in
    {
      imports = [
        (self + "/lib/network/network-schema.nix")
      ];

      options.frablab.homelab.network = {
        subnet = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Subnet name in constants/network.nix (e.g. 'mgmt', 'service'). If null, defaults to DHCP.";
        };

        interface = lib.mkOption {
          type = lib.types.nullOr (lib.types.either lib.types.str (lib.types.listOf lib.types.str));
          default = null;
          description = "Network interface to use for static networking. Defaults to eth0 for containers, ens18 for VMs.";
        };

        dns = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = lib.optional (
            clusterNet.hosts.service.bifrost.ip or null != null
          ) clusterNet.hosts.service.bifrost.ip;
          description = "DNS servers to configure. Defaults to Bifrost (AdGuard Home).";
        };
      };

      config = lib.mkMerge [
        {
          frablab.network = lib.mkDefault (import (self + "/constants/network.nix"));

          networking = {
            # Priority 900 overrides base-networking's mkDefault (1000) with cluster domain,
            # while still allowing a per-host normal assignment (100) to override it.
            domain = lib.mkOverride 900 clusterNet.domain;
            search = lib.mkOverride 900 [ clusterNet.domain ];
          };
        }

        (lib.mkIf (cfg.subnet != null) {
          systemd.network.networks."10-default" = {
            matchConfig.Name = interfaceName;
            networkConfig = {
              Address = hostData.address;
              Gateway = subnetData.gateway.ip;
              DNS = cfg.dns;
            };
          };
        })
      ];
    };
}
