{ lib }:
let
  eval =
    networkConfig:
    (lib.evalModules {
      modules = [
        ../network/network-schema.nix
        { frablab.network = networkConfig; }
      ];
    }).config.frablab.network;

  validNetwork = {
    ns = "mimir.service.home.arpa.";
    adminEmail = "admin@home.arpa";
    dns = [ "1.1.1.1" ];
    extraRecords = {
      subdomains.wild = {
        TXT = [ "ok" ];
      };
    };
    subnets = {
      main = {
        id = 1;
        cidr = "192.168.1.0/24";
        cidr6 = "fd00:42:1::/64";
        gateway = "192.168.1.254";
        dhcp = {
          start = "192.168.1.100";
          end = "192.168.1.200";
        };
        hosts = {
          server = "192.168.1.10";
          dualStack = {
            ipv4 = "192.168.1.30";
            ipv6 = "fd00:42:1::30";
          };
          printer = {
            ipv4 = "192.168.1.50";
            mac = "00:11:22:33:44:55";
            aliases = [
              "print"
              "canon"
            ];
          };
        };
      };
      iot = {
        id = 2;
        cidr = "192.168.2.0/24";
        gateway = "192.168.2.254";
        dns = [ "8.8.8.8" ];
      };
      dual = {
        id = 3;
        cidr = "192.168.3.0/24";
        gateway = "192.168.3.254";
        dns = {
          ipv4 = "9.9.9.9";
          ipv6 = "2620:fe::fe";
        };
      };
    };
  };

  validResult = eval validNetwork;

  mergedResult =
    (lib.evalModules {
      modules = [
        ../network/network-schema.nix
        {
          frablab.network = validNetwork // {
            extraRecords = {
              TXT = [ "root-a" ];
              subdomains.alpha.TXT = [ "a" ];
            };
          };
        }
        {
          frablab.network.extraRecords = {
            CAA = [
              {
                issuer = "letsencrypt.org";
                tag = "issue";
              }
            ];
            subdomains.beta.TXT = [ "b" ];
          };
        }
      ];
    }).config.frablab.network;

  tests = {
    testDefaultDomain = {
      expr = validResult.domain;
      expected = "home.arpa";
    };
    testSubnetCidr = {
      expr = validResult.subnets.main.cidr;
      expected = "192.168.1.0/24";
    };
    testSubnetMask = {
      expr = validResult.subnets.main.mask;
      expected = 24;
    };
    testSubnetCidr6 = {
      expr = validResult.subnets.main.cidr6;
      expected = "fd00:42:1::/64";
    };
    testSubnetReverseZone = {
      expr = validResult.subnets.main.reverseZone;
      expected = "1.168.192.in-addr.arpa";
    };
    testSubnetReverseZone6 = {
      expr = validResult.subnets.main.reverseZone6;
      expected = "0.0.0.0.1.0.0.0.2.4.0.0.0.0.d.f.ip6.arpa";
    };
    testHostIpv4 = {
      expr = validResult.hosts.main.server.ipv4;
      expected = "192.168.1.10";
    };
    testHostAddress = {
      expr = validResult.hosts.main.server.address;
      expected = "192.168.1.10/24";
    };
    testDualStackHostIpv4 = {
      expr = validResult.hosts.main.dualStack.ipv4;
      expected = "192.168.1.30";
    };
    testDualStackHostIpv6 = {
      expr = validResult.hosts.main.dualStack.ipv6;
      expected = "fd00:42:1::30";
    };
    testDualStackHostAddress6 = {
      expr = validResult.hosts.main.dualStack.address6;
      expected = "fd00:42:1::30/64";
    };
    testHostFqdn = {
      expr = validResult.hosts.main.server.fqdn;
      expected = "server.main.home.arpa";
    };
    testGatewayIpv4 = {
      expr = validResult.subnets.main.gateway.ipv4;
      expected = "192.168.1.254";
    };
    testGatewayName = {
      expr = validResult.subnets.main.gateway.name;
      expected = "gateway";
    };
    testGatewayFqdn = {
      expr = validResult.subnets.main.gateway.fqdn;
      expected = "gateway.main.home.arpa";
    };
    testDerivedGatewayHostIpv4 = {
      expr = validResult.hosts.main.gateway.ipv4;
      expected = "192.168.1.254";
    };
    testDerivedGatewayHostFqdn = {
      expr = validResult.hosts.main.gateway.fqdn;
      expected = "gateway.main.home.arpa";
    };
    testGlobalDnsIpv4 = {
      expr = validResult.dns.ipv4;
      expected = [ "1.1.1.1" ];
    };
    testGlobalDnsIpv6 = {
      expr = validResult.dns.ipv6;
      expected = [ ];
    };
    testGlobalDnsServers = {
      expr = validResult.dns.servers;
      expected = [ "1.1.1.1" ];
    };
    testSubnetDefaultDnsIpv4 = {
      expr = validResult.subnets.main.dns.ipv4;
      expected = [ "1.1.1.1" ];
    };
    testSubnetDefaultDnsServers = {
      expr = validResult.subnets.main.dns.servers;
      expected = [ "1.1.1.1" ];
    };
    testSubnetOverrideDnsIpv4 = {
      expr = validResult.subnets.iot.dns.ipv4;
      expected = [ "8.8.8.8" ];
    };
    testSubnetDualDnsIpv4 = {
      expr = validResult.subnets.dual.dns.ipv4;
      expected = [ "9.9.9.9" ];
    };
    testSubnetDualDnsIpv6 = {
      expr = validResult.subnets.dual.dns.ipv6;
      expected = [ "2620:fe::fe" ];
    };
    testSubnetDualDnsServers = {
      expr = validResult.subnets.dual.dns.servers;
      expected = [
        "9.9.9.9"
        "2620:fe::fe"
      ];
    };
    testHostMac = {
      expr = validResult.hosts.main.printer.mac;
      expected = "00:11:22:33:44:55";
    };
    testHostAliases = {
      expr = validResult.hosts.main.printer.aliases;
      expected = [
        "print"
        "canon"
      ];
    };
    testHostNameDerived = {
      expr = validResult.hosts.main.printer.name;
      expected = "printer";
    };
    testExtraRecords = {
      expr = validResult.extraRecords.subdomains.wild.TXT;
      expected = [ "ok" ];
    };
    testExtraRecordsMerge = {
      expr = {
        apexTxt = mergedResult.extraRecords.TXT;
        apexCaa = mergedResult.extraRecords.CAA;
        alpha = mergedResult.extraRecords.subdomains.alpha.TXT;
        beta = mergedResult.extraRecords.subdomains.beta.TXT;
      };
      expected = {
        apexTxt = [ "root-a" ];
        apexCaa = [
          {
            issuer = "letsencrypt.org";
            tag = "issue";
          }
        ];
        alpha = [ "a" ];
        beta = [ "b" ];
      };
    };
  };
in
lib.runTests tests
