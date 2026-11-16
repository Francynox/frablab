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

  recursiveMerge =
    lhs: rhs:
    lhs
    // (builtins.mapAttrs (
      key: rval:
      if builtins.isAttrs rval && builtins.isAttrs (lhs.${key} or null) then
        recursiveMerge lhs.${key} rval
      else
        rval
    ) rhs);

  mkForwardZone =
    {
      serial ? 1,
    }:
    let
      base = mkSOA { inherit serial; };
      v4Dns = network.dns.ipv4 or [ ];
      v6Dns = network.dns.ipv6 or [ ];
      dnsRecord =
        let
          records =
            (if v4Dns != [ ] then { A = v4Dns; } else { }) // (if v6Dns != [ ] then { AAAA = v6Dns; } else { });
        in
        if records != { } then { dns = records; } else { };
      hostRecords = builtins.mapAttrs (_sname: shosts: {
        subdomains = builtins.mapAttrs (
          _hname: hdata:
          {
            A = [ hdata.ipv4 ];
          }
          // (if hdata.ipv6 != null then { AAAA = [ hdata.ipv6 ]; } else { })
        ) shosts;
      }) network.hosts;

      allHosts = builtins.concatMap builtins.attrValues (builtins.attrValues network.hosts);

      aliasRecords = builtins.listToAttrs (
        builtins.concatMap (
          hdata:
          map (alias: {
            name = alias;
            value = {
              CNAME = [ "${hdata.fqdn}." ];
            };
          }) hdata.aliases
        ) allHosts
      );

      extraSubdomains = network.extraRecords.subdomains or { };
      extraApex = builtins.removeAttrs network.extraRecords [ "subdomains" ];

      mergedSubdomains = builtins.foldl' recursiveMerge { } [
        dnsRecord
        hostRecords
        aliasRecords
        extraSubdomains
      ];
    in
    mkZone domain (base // extraApex // { subdomains = mergedSubdomains; });

  mkDynamicForwardZone = mkZone dhcpDomain (mkSOA { });

  mkDynamicReverseZone =
    {
      sname,
    }:
    mkZone subnets.${sname}.reverseZone (mkSOA { });

  staticZoneFiles = {
    "db.${domain}" = mkForwardZone { inherit serial; };
  };

  mkDynamicZones =
    let
      dyndFwd = {
        "dhcp/db.${dhcpDomain}" = mkDynamicForwardZone;
      };
      dyndRev = builtins.listToAttrs (
        map (sname: {
          name = "db.${sname}";
          value = mkDynamicReverseZone { inherit sname; };
        }) (builtins.attrNames subnets)
      );
    in
    dyndFwd // dyndRev;
in
{
  lib = {
    inherit mkZone mkSOA;
  };
  inherit staticZoneFiles;
  dynamicZoneFiles = mkDynamicZones;
}
