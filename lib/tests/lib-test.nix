{ lib, dns }:
let
  network =
    (lib.evalModules {
      modules = [
        ../network/network-schema.nix
        {
          frablab.network = {
            domain = "home.arpa";
            dhcpDomain = "dhcp.home.arpa";
            ns = "mimir.service.home.arpa.";
            adminEmail = "admin@home.arpa";
            dns = {
              ipv4 = [ "192.168.1.1" ];
              ipv6 = [ "fd00:42:1::1" ];
            };
            extraRecords = {
              subdomains.wild = {
                TXT = [ "hello" ];
              };
            };
            subnets = {
              main = {
                id = 1;
                cidr = "192.168.1.0/24";
                gateway = "192.168.1.254";
                dhcp = {
                  start = "192.168.1.100";
                  end = "192.168.1.200";
                };
                hosts = {
                  server = "192.168.1.10";
                  printer = {
                    ipv4 = "192.168.1.50";
                    mac = "00:11:22:33:44:55";
                    aliases = [ "print" ];
                  };
                };
              };
              iot = {
                id = 2;
                cidr = "192.168.2.0/24";
                gateway = "192.168.2.254";
                dhcp = {
                  start = "192.168.2.100";
                  end = "192.168.2.200";
                };
                dns = "8.8.8.8";
              };
              staticOnly = {
                id = 3;
                cidr = "192.168.3.0/29";
                gateway = "192.168.3.6";
                hosts = {
                  box = "192.168.3.2";
                };
              };
            };
          };
        }
      ];
    }).config.frablab.network;

  kea = import ../network/kea.nix { inherit network; };
  dhcp4 = kea.mkDhcp4Config { dnsServers = [ "192.168.1.1" ]; };
  dhcpDdns = kea.mkDhcpDdnsConfig { dhcpDdnsKeyPath = "/etc/kea/key"; };
  zones = import ../network/dns.nix {
    inherit network dns;
    serial = 1;
  };
  bind = import ../network/bind.nix { inherit network lib; };
  namedConf = bind.namedConf {
    dataDir = "/var/lib/bind";
    dhcpKeyFile = "/etc/bind/key";
  };

  subnetMain = builtins.head (builtins.filter (s: s.subnet == "192.168.1.0/24") dhcp4.Dhcp4.subnet4);
  subnetIot = builtins.head (builtins.filter (s: s.subnet == "192.168.2.0/24") dhcp4.Dhcp4.subnet4);

  tests = {
    testKeaSubnetCidr = {
      expr = subnetMain.subnet;
      expected = "192.168.1.0/24";
    };
    testKeaPool = {
      expr = (builtins.elemAt subnetMain.pools 0).pool;
      expected = "192.168.1.100 - 192.168.1.200";
    };
    testKeaRouter = {
      expr = (builtins.head (builtins.filter (o: o.name == "routers") subnetMain.option-data)).data;
      expected = "192.168.1.254";
    };
    testKeaDdnsSuffix = {
      expr = subnetMain.ddns-qualifying-suffix;
      expected = "main.dhcp.home.arpa";
    };
    testKeaDdnsReverseDomain = {
      expr = builtins.any (
        d: d.name == "1.168.192.in-addr.arpa."
      ) dhcpDdns.DhcpDdns.reverse-ddns.ddns-domains;
      expected = true;
    };
    testDnsStaticForwardZone = {
      expr = zones.staticZoneFiles ? "db.home.arpa";
      expected = true;
    };
    testDnsDynamicReverseZone = {
      expr = zones.dynamicZoneFiles ? "db.main";
      expected = true;
    };
    testBindNamedConfHasForwardZone = {
      expr = lib.hasInfix "zone \"home.arpa\"" namedConf;
      expected = true;
    };
    testBindNamedConfHasReverseZone = {
      expr = lib.hasInfix "zone \"1.168.192.in-addr.arpa\"" namedConf;
      expected = true;
    };
    testDnsForwardZoneHasGateway = {
      expr = lib.hasInfix "gateway.main IN A 192.168.1.254" zones.staticZoneFiles."db.home.arpa";
      expected = true;
    };
    testBindNsupdateHasGatewayPtr = {
      expr = lib.hasInfix "update add 254.1.168.192.in-addr.arpa. 86400 PTR gateway.main.home.arpa." bind.nsupdateScriptContent;
      expected = true;
    };
    testDnsForwardZoneHasGlobalDns = {
      expr = lib.hasInfix "dns IN A 192.168.1.1" zones.staticZoneFiles."db.home.arpa";
      expected = true;
    };
    testDnsForwardZoneHasGlobalIpv6Dns = {
      expr = lib.hasInfix "dns IN AAAA fd00:42:1::1" zones.staticZoneFiles."db.home.arpa";
      expected = true;
    };
    testKeaGlobalDns = {
      expr =
        (builtins.head (builtins.filter (o: o.name == "domain-name-servers") dhcp4.Dhcp4.option-data)).data;
      expected = "192.168.1.1";
    };
    testKeaSubnetOverrideDns = {
      expr =
        (builtins.head (builtins.filter (o: o.name == "domain-name-servers") subnetIot.option-data)).data;
      expected = "8.8.8.8";
    };
    testKeaReservationHwAddress = {
      expr = (builtins.elemAt subnetMain.reservations 0).hw-address;
      expected = "00:11:22:33:44:55";
    };
    testKeaReservationIpAddress = {
      expr = (builtins.elemAt subnetMain.reservations 0).ip-address;
      expected = "192.168.1.50";
    };
    testDnsForwardZoneHasAlias = {
      expr = lib.hasInfix "print IN CNAME printer.main.home.arpa." zones.staticZoneFiles."db.home.arpa";
      expected = true;
    };
    testDnsForwardZoneHasExtraTxt = {
      expr = lib.hasInfix "wild IN TXT \"hello\"" zones.staticZoneFiles."db.home.arpa";
      expected = true;
    };
    testKeaSubnetCountExcludesNonDhcp = {
      expr = builtins.length dhcp4.Dhcp4.subnet4;
      expected = 2;
    };
    testKeaDdnsReverseDomainExcludesNonDhcp = {
      expr = builtins.any (
        d: d.name == "3.168.192.in-addr.arpa."
      ) dhcpDdns.DhcpDdns.reverse-ddns.ddns-domains;
      expected = false;
    };
    testBindNamedConfIncludesNonDhcpReverseZone = {
      expr = lib.hasInfix "zone \"3.168.192.in-addr.arpa\"" namedConf;
      expected = true;
    };
  };
in
lib.runTests tests
