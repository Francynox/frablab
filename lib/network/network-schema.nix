{ lib, config, ... }:
let
  networkDomain = config.frablab.network.domain;

  hostSubmodule =
    subnetName: subnetPrefix: subnetMask:
    lib.types.submodule (
      { name, config, ... }:
      {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            default = name;
          };
          hostPart = lib.mkOption { type = lib.types.str; };
          ip = lib.mkOption {
            type = lib.types.str;
            default = "${subnetPrefix}.${config.hostPart}";
          };
          mask = lib.mkOption {
            type = lib.types.int;
            default = subnetMask;
          };
          address = lib.mkOption {
            type = lib.types.str;
            default = "${config.ip}/${toString config.mask}";
          };
          fqdn = lib.mkOption {
            type = lib.types.str;
            default = "${config.name}.${subnetName}.${networkDomain}";
          };
        };
      }
    );

  hostType =
    subnetName: subnetPrefix: subnetMask:
    lib.types.coercedTo lib.types.str (octet: { hostPart = octet; }) (
      hostSubmodule subnetName subnetPrefix subnetMask
    );

  subnetSubmodule = lib.types.submodule (
    { name, config, ... }:
    {
      options = {
        id = lib.mkOption { type = lib.types.int; };
        prefix = lib.mkOption { type = lib.types.str; };
        mask = lib.mkOption {
          type = lib.types.int;
          default = 24;
        };

        dhcpRange = lib.mkOption {
          default = {
            start = 100;
            end = 200;
          };
          type = lib.types.submodule {
            options = {
              start = lib.mkOption {
                type = lib.types.int;
                default = 100;
              };
              end = lib.mkOption {
                type = lib.types.int;
                default = 200;
              };
            };
          };
        };

        validLifetime = lib.mkOption {
          type = lib.types.nullOr lib.types.int;
          default = null;
        };

        hosts = lib.mkOption {
          type = lib.types.attrsOf (hostType name config.prefix config.mask);
          default = { };
        };
      };

      config.hosts = {
        gateway = lib.mkDefault "254";
        gateway-master = lib.mkDefault "252";
        gateway-slave = lib.mkDefault "253";
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

    subnets = lib.mkOption {
      type = lib.types.attrsOf subnetSubmodule;
      default = { };
      apply =
        subnets:
        lib.mapAttrs (
          name: subnet:
          if !(subnet.dhcpRange.start <= subnet.dhcpRange.end) then
            throw "Subnet '${name}': DHCP start range must be <= end range."
          else if !(subnet.dhcpRange.end < 255) then
            throw "Subnet '${name}': DHCP end range must be < 255."
          else
            subnet
        ) subnets;
    };

    hosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.unspecified);
      description = "Derived map of all hosts grouped by subnet. Read-only by design.";
    };
  };

  config.frablab.network.hosts = lib.mkForce (
    lib.mapAttrs (_name: subnet: subnet.hosts) config.frablab.network.subnets
  );
}
