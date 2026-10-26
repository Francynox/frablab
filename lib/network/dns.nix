{
  serial ? 1,
  dns,
  network,
}:
let
  inherit (network)
    ns
    adminEmail
    domain
    dhcpDomain
    subnets
    ;

  reversePrefix = import ./reverse-prefix.nix;

  mkZone = origin: zoneContent: dns.lib.toString origin (zoneContent // { useOrigin = true; });

  mkSOA =
    {
      serial ? 1,
      ...
    }:
    {
      SOA = {
        nameServer = ns;
        inherit adminEmail;
        inherit serial;
        refresh = 3600;
        retry = 900;
        expire = 604800;
        minimum = 86400;
      };
      NS = [ ns ];
    };

  mkForwardZone =
    {
      serial ? 1,
    }:
    let
      base = mkSOA { inherit serial; };
      hostRecords = builtins.mapAttrs (_sname: shosts: {
        subdomains = builtins.mapAttrs (_hname: hdata: {
          A = [ hdata.ip ];
        }) shosts;
      }) network.hosts;
    in
    mkZone domain (base // { subdomains = hostRecords; });

  mkDynamicForwardZone = mkZone dhcpDomain (mkSOA { });

  mkDynamicReverseZone =
    {
      sname,
    }:
    let
      revPrefix = reversePrefix subnets.${sname}.prefix;
      origin = "${revPrefix}.in-addr.arpa";
    in
    mkZone origin (mkSOA { });

  mkStaticZones =
    {
      serial ? 1,
    }:
    {
      "db.${domain}" = mkForwardZone { inherit serial; };
    };

  mkDynamicZones =
    let
      dyndFwd = {
        "dhcp/db.${dhcpDomain}" = mkDynamicForwardZone;
      };
      dyndRev = builtins.listToAttrs (
        map (sname: {
          name = "db.${subnets.${sname}.prefix}";
          value = mkDynamicReverseZone { inherit sname; };
        }) (builtins.attrNames subnets)
      );
    in
    dyndFwd // dyndRev;
in
{
  lib = {
    inherit mkZone mkSOA reversePrefix;
  };
  staticZoneFiles = mkStaticZones { inherit serial; };
  dynamicZoneFiles = mkDynamicZones;
}
