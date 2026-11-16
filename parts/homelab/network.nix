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
      subnet = clusterNet.subnets.${cfg.subnet} or null;
      hostData = clusterNet.hosts.${cfg.subnet}.${config.networking.hostName} or null;
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
          default = if subnet != null then subnet.dns.servers else clusterNet.dns.servers;
          description = "DNS servers to configure. Defaults to the subnet or global cluster DNS.";
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
          assertions = [
            {
              assertion = subnet != null;
              message = "frablab.homelab.network: unknown subnet '${cfg.subnet}' for host '${config.networking.hostName}'. Valid subnets: ${lib.concatStringsSep ", " (lib.attrNames clusterNet.subnets)}";
            }
            {
              assertion = hostData != null;
              message = "frablab.homelab.network: host '${config.networking.hostName}' not found in subnet '${cfg.subnet}'. Available hosts: ${
                lib.concatStringsSep ", " (lib.attrNames (clusterNet.hosts.${cfg.subnet} or { }))
              }";
            }
          ];

          systemd.network.networks."10-default" = {
            matchConfig.Name = interfaceName;
            networkConfig = {
              Address =
                if hostData != null && hostData.address6 != null then
                  [
                    hostData.address
                    hostData.address6
                  ]
                else if hostData != null then
                  hostData.address
                else
                  [ ];
              Gateway =
                if subnet != null && subnet.gateway.ipv6 != null then
                  [
                    subnet.gateway.ipv4
                    subnet.gateway.ipv6
                  ]
                else if subnet != null then
                  subnet.gateway.ipv4
                else
                  [ ];
              DNS = cfg.dns;
            };
          };
        })
      ];
    };
}
