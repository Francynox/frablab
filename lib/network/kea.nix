{ network }:
let
  reversePrefix = import ./reverse-prefix.nix;

  inherit (network)
    subnets
    hosts
    dhcpDomain
    ;

  mkSubnet4 =
    name: subnet:
    {
      inherit (subnet) id;
      subnet = "${subnet.prefix}.0/${toString subnet.mask}";
      pools = [
        {
          pool = "${subnet.prefix}.${toString subnet.dhcpRange.start} - ${subnet.prefix}.${toString subnet.dhcpRange.end}";
        }
      ];
      option-data = [
        {
          name = "routers";
          data = hosts.${name}.gateway.ip;
        }
        {
          name = "domain-name";
          data = "${name}.${dhcpDomain}";
        }
      ];
      ddns-qualifying-suffix = "${name}.${dhcpDomain}";
    }
    // (if subnet.validLifetime != null then { valid-lifetime = subnet.validLifetime; } else { });

  mkDhcp4Config =
    {
      interfaces ? [ "*" ],
      leaseFile ? "/var/lib/kea/dhcp4.leases",
      socketPath ? "/run/kea/kea-dhcp4.socket",
      dnsServers ? [ ],
    }:
    {
      Dhcp4 = {
        interfaces-config = {
          inherit interfaces;
        };
        control-sockets = [
          {
            socket-type = "unix";
            socket-name = socketPath;
          }
        ];
        lease-database = {
          type = "memfile";
          persist = true;
          lfc-interval = 3600;
          name = leaseFile;
        };
        expired-leases-processing = {
          reclaim-timer-wait-time = 10;
          flush-reclaimed-timer-wait-time = 25;
          hold-reclaimed-time = 3600;
          max-reclaim-leases = 100;
          max-reclaim-time = 250;
          unwarned-reclaim-cycles = 5;
        };

        valid-lifetime = 86400;

        option-data = [
          {
            name = "domain-name-servers";
            data = builtins.concatStringsSep "," dnsServers;
          }
        ];

        subnet4 = builtins.attrValues (builtins.mapAttrs mkSubnet4 subnets);

        dhcp-ddns = {
          enable-updates = true;
        };
        ddns-send-updates = true;
        ddns-qualifying-suffix = dhcpDomain;
        ddns-override-client-update = true;
        ddns-override-no-update = true;
        ddns-update-on-renew = true;
      };
    };

  mkDhcpDdnsConfig =
    {
      socketPath ? "/run/kea/kea-dhcp-ddns.socket",
      dnsServerIp ? "127.0.0.1",
      dnsServerPort ? 53,
      dhcpDdnsKeyPath ? "__SECRET_PLACEHOLDER__",
    }:
    let
      forwardZone = {
        name = "${dhcpDomain}.";
        key-name = "dhcp-key";
        dns-servers = [
          {
            ip-address = dnsServerIp;
            port = dnsServerPort;
          }
        ];
      };

      reverseZones = builtins.attrValues (
        builtins.mapAttrs (_name: subnet: {
          name = "${reversePrefix subnet.prefix}.in-addr.arpa.";
          key-name = "dhcp-key";
          dns-servers = [
            {
              ip-address = dnsServerIp;
              port = dnsServerPort;
            }
          ];
        }) subnets
      );
    in
    {
      DhcpDdns = {
        tsig-keys = [
          {
            name = "dhcp-key";
            algorithm = "hmac-sha256";
            secret-file = dhcpDdnsKeyPath;
          }
        ];
        ip-address = "127.0.0.1";
        port = 53001;
        control-sockets = [
          {
            socket-type = "unix";
            socket-name = socketPath;
          }
        ];
        forward-ddns = {
          ddns-domains = [ forwardZone ];
        };
        reverse-ddns = {
          ddns-domains = reverseZones;
        };
      };
    };
in
{
  inherit mkDhcp4Config mkDhcpDdnsConfig;
}
