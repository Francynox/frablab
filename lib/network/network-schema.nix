{ lib, config, ... }:
let
  networkDomain = config.frablab.network.domain;
  networkDns = config.frablab.network.dns;

  baseHostSubmodule =
    subnetName: subnet: defaultHostName: isReadOnly:
    lib.types.submodule (
      { name, config, ... }:
      {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            default = defaultHostName name;
            readOnly = isReadOnly;
            description = "DNS hostname for the host.";
          };

          ipv4 = lib.mkOption {
            type = lib.types.str;
            description = "IPv4 address of the host.";
          };

          ipv6 = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Optional IPv6 address of the host.";
          };

          address = lib.mkOption {
            type = lib.types.str;
            default = "${config.ipv4}/${toString subnet.mask}";
            readOnly = true;
            description = "IPv4 address in CIDR notation for systemd.network.";
          };

          address6 = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default =
              if config.ipv6 != null && subnet.mask6 != null then
                "${config.ipv6}/${toString subnet.mask6}"
              else
                null;
            readOnly = true;
            description = "IPv6 address in CIDR notation for systemd.network.";
          };

          mac = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Optional MAC / hardware address for DHCP static reservation.";
          };

          aliases = lib.mkOption {
            type = lib.types.coercedTo lib.types.str lib.singleton (lib.types.listOf lib.types.str);
            default = [ ];
            description = "List of alias domain names (CNAMEs) pointing to this host.";
          };

          fqdn = lib.mkOption {
            type = lib.types.str;
            default = "${config.name}.${subnetName}.${networkDomain}";
            readOnly = true;
            description = "Fully qualified domain name for the host.";
          };
        };
      }
    );

  hostSubmodule = subnetName: subnet: baseHostSubmodule subnetName subnet (n: n) true;

  hostType =
    subnetName: subnet:
    lib.types.coercedTo lib.types.str (addr: { ipv4 = addr; }) (hostSubmodule subnetName subnet);

  gatewaySubmodule = subnetName: subnet: baseHostSubmodule subnetName subnet (_: "gateway") false;

  gatewayType =
    subnetName: subnet:
    lib.types.coercedTo lib.types.str (addr: { ipv4 = addr; }) (gatewaySubmodule subnetName subnet);

  dhcpSubmodule = lib.types.submodule {
    options = {
      start = lib.mkOption {
        type = lib.types.str;
        description = "Start IPv4 of DHCP pool.";
      };
      end = lib.mkOption {
        type = lib.types.str;
        description = "End IPv4 of DHCP pool.";
      };
      validLifetime = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.positive;
        default = null;
        description = "DHCP lease valid lifetime in seconds.";
      };
    };
  };

  dnsSubmodule = lib.types.submodule (
    { config, ... }:
    {
      options = {
        ipv4 = lib.mkOption {
          type = lib.types.coercedTo lib.types.str lib.singleton (lib.types.listOf lib.types.str);
          default = [ ];
          description = "IPv4 DNS server addresses.";
        };

        ipv6 = lib.mkOption {
          type = lib.types.coercedTo lib.types.str lib.singleton (lib.types.listOf lib.types.str);
          default = [ ];
          description = "IPv6 DNS server addresses.";
        };

        servers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = config.ipv4 ++ config.ipv6;
          readOnly = true;
          description = "Combined list of IPv4 and IPv6 DNS server addresses.";
        };
      };
    }
  );

  dnsType = lib.types.coercedTo (lib.types.either lib.types.str (lib.types.listOf lib.types.str)) (
    v: { ipv4 = lib.toList v; }) dnsSubmodule;

  extraRecordsSubmodule = lib.types.submodule {
    freeformType = lib.types.attrsOf lib.types.anything;
    options.subdomains = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
      default = { };
      description = "Extra subdomain records for the forward zone.";
    };
  };

  subnetSubmodule = lib.types.submodule (
    { name, config, ... }:
    let
      cidrParts = lib.splitString "/" config.cidr;
      netIp = builtins.elemAt cidrParts 0;
      netMask = lib.toIntBase10 (builtins.elemAt cidrParts 1);
    in
    {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          default = name;
          readOnly = true;
          description = "Subnet name derived from the attribute key.";
        };

        id = lib.mkOption {
          type = lib.types.ints.between 1 4094;
          description = "IEEE 802.1Q VLAN ID (1–4094).";
        };

        cidr = lib.mkOption {
          type = lib.types.str;
          description = "IPv4 network in CIDR notation (e.g. '10.0.90.0/24').";
        };

        network = lib.mkOption {
          type = lib.types.str;
          default = netIp;
          readOnly = true;
          description = "Network base IP address.";
        };

        mask = lib.mkOption {
          type = lib.types.int;
          default = netMask;
          readOnly = true;
          description = "Subnet mask prefix length.";
        };

        reverseZone = lib.mkOption {
          type = lib.types.str;
          default =
            let
              # Enclosing /24 boundary (subnets /24../30 use 3 octets):
              octets = lib.take 3 (lib.splitString "." netIp);
            in
            "${lib.concatStringsSep "." (lib.reverseList octets)}.in-addr.arpa";
          readOnly = true;
          description = "Reverse DNS zone name (e.g. '90.0.10.in-addr.arpa').";
        };

        cidr6 = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Optional IPv6 network in CIDR notation (e.g. 'fd00:42:6::/64').";
        };

        mask6 = lib.mkOption {
          type = lib.types.nullOr lib.types.int;
          default =
            if config.cidr6 != null then
              lib.toIntBase10 (builtins.elemAt (lib.splitString "/" config.cidr6) 1)
            else
              null;
          readOnly = true;
          description = "IPv6 subnet mask prefix length.";
        };

        reverseZone6 = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default =
            if config.cidr6 == null then
              null
            else
              let
                parts = lib.splitString "/" config.cidr6;
                netIp = builtins.elemAt parts 0;

                splitDouble = lib.splitString "::" netIp;
                words =
                  if builtins.length splitDouble == 2 then
                    let
                      leftStr = builtins.elemAt splitDouble 0;
                      rightStr = builtins.elemAt splitDouble 1;
                      left = if leftStr == "" then [ ] else lib.splitString ":" leftStr;
                      right = if rightStr == "" then [ ] else lib.splitString ":" rightStr;
                      missing = 8 - (builtins.length left + builtins.length right);
                    in
                    left ++ (lib.genList (_: "0") missing) ++ right
                  else
                    lib.splitString ":" netIp;

                hexStr = lib.toLower (lib.concatMapStrings (lib.fixedWidthString 4 "0") words);
                nibbles = lib.take (config.mask6 / 4) (lib.stringToCharacters hexStr);
              in
              "${lib.concatStringsSep "." (lib.reverseList nibbles)}.ip6.arpa";
          readOnly = true;
          description = "Optional reverse DNS zone name for IPv6 (e.g. '0.0.0.0.6.0.0.0.2.4.0.0.0.0.d.f.ip6.arpa').";
        };

        gateway = lib.mkOption {
          type = gatewayType name config;
          description = "Subnet default gateway.";
        };

        dhcp = lib.mkOption {
          type = lib.types.nullOr dhcpSubmodule;
          default = null;
          description = "DHCP configuration.";
        };

        dns = lib.mkOption {
          type = dnsType;
          default = {
            inherit (networkDns) ipv4 ipv6;
          };
          description = "DNS server IP addresses for this subnet (defaults to global network.dns).";
        };

        hosts = lib.mkOption {
          type = lib.types.attrsOf (hostType name config);
          default = { };
          description = "Static hosts in this subnet.";
        };
      };
    }
  );
in
{
  options.frablab.network = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = "home.arpa";
    };
    dhcpDomain = lib.mkOption {
      type = lib.types.str;
      default = "dhcp.home.arpa";
    };
    ns = lib.mkOption { type = lib.types.str; };
    adminEmail = lib.mkOption { type = lib.types.str; };

    dns = lib.mkOption {
      type = dnsType;
      default = { };
      description = "Global default DNS server IP addresses.";
    };

    subnets = lib.mkOption {
      type = lib.types.attrsOf subnetSubmodule;
      default = { };
    };

    extraRecords = lib.mkOption {
      type = extraRecordsSubmodule;
      default = { };
      description = "Extra DNS records to include in the forward zone (e.g. apex records, TXT, SRV, wildcard).";
    };

    hosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.attrs);
      readOnly = true;
      default = lib.mapAttrs (
        _sname: subnet:
        {
          ${subnet.gateway.name} = subnet.gateway;
        }
        // subnet.hosts
      ) config.frablab.network.subnets;
      description = "Derived map of all hosts grouped by subnet. Read-only by design.";
    };
  };
}
