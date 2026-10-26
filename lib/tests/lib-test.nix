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
            subnets.main = {
              id = 1;
              prefix = "192.168.1";
              hosts.server = "10";
            };
          };
        }
      ];
    }).config.frablab.network;

  reversePrefix = import ../network/reverse-prefix.nix;
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

  subnet0 = builtins.elemAt dhcp4.Dhcp4.subnet4 0;

  tests = {
    testReversePrefix3 = {
      expr = reversePrefix "10.0.80";
      expected = "80.0.10";
    };
    testReversePrefix2 = {
      expr = reversePrefix "10.0";
      expected = "0.10";
    };
    testKeaSubnetCidr = {
      expr = subnet0.subnet;
      expected = "192.168.1.0/24";
    };
    testKeaPool = {
      expr = (builtins.elemAt subnet0.pools 0).pool;
      expected = "192.168.1.100 - 192.168.1.200";
    };
    testKeaRouter = {
      expr = (builtins.head (builtins.filter (o: o.name == "routers") subnet0.option-data)).data;
      expected = "192.168.1.254";
    };
    testKeaDdnsSuffix = {
      expr = subnet0.ddns-qualifying-suffix;
      expected = "main.dhcp.home.arpa";
    };
    testKeaDdnsReverseDomain = {
      expr = (builtins.elemAt dhcpDdns.DhcpDdns.reverse-ddns.ddns-domains 0).name;
      expected = "1.168.192.in-addr.arpa.";
    };
    testDnsStaticForwardZone = {
      expr = zones.staticZoneFiles ? "db.home.arpa";
      expected = true;
    };
    testDnsDynamicReverseZone = {
      expr = zones.dynamicZoneFiles ? "db.192.168.1";
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
  };
in
lib.runTests tests
