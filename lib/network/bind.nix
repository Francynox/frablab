{
  network,
  lib,
}:
let
  reversePrefix = import ./reverse-prefix.nix;

  inherit (network) subnets domain dhcpDomain;

  mkStaticZoneBlock = name: file: ''
    zone "${name}" {
        type primary;
        file "${file}";
    };
  '';

  mkDhcpZoneBlock = name: file: rrTypes: ''
    zone "${name}" {
        type primary;
        file "${file}";
        update-policy { grant dhcp-key zonesub ${rrTypes} DHCID; };
    };
  '';

  namedConf =
    {
      dhcpKeyFile ? "/etc/bind/dhcp-ddns.key",
      dataDir ? "/var/lib/bind",
    }:
    let
      reverseZoneBlocks = builtins.concatStringsSep "\n" (
        map (
          sname:
          let
            subnet = subnets.${sname};
            revPrefix = reversePrefix subnet.prefix;
          in
          ''
            // ${sname} (${subnet.prefix}.0/${toString subnet.mask})
            ${mkDhcpZoneBlock "${revPrefix}.in-addr.arpa" "${dataDir}/db.${subnet.prefix}" "PTR"}
          ''
        ) (builtins.attrNames subnets)
      );
    in
    ''
      options {
          directory "${dataDir}";
          recursion no;
          allow-query { any; };
          allow-transfer { none; };
          listen-on port 53 { any; };
          listen-on-v6 port 53 { any; };
      };

      include "${dhcpKeyFile}";

      // Forward Zones
      ${mkStaticZoneBlock domain "${dataDir}/db.${domain}"}
      ${mkDhcpZoneBlock dhcpDomain "${dataDir}/dhcp/db.${dhcpDomain}" "A"}

      // Reverse Zones
      ${reverseZoneBlocks}
    '';

  nsupdateScriptContent =
    let
      nonDhcpOctets =
        subnet:
        let
          inherit (subnet.dhcpRange) start;
          inherit (subnet.dhcpRange) end;
        in
        (lib.range 1 (start - 1)) ++ (lib.range (end + 1) 254);

      commands = lib.concatLists (
        lib.mapAttrsToList (
          sname: subnet:
          let
            revPrefix = reversePrefix subnet.prefix;
            zone = "${revPrefix}.in-addr.arpa";
            staticOctets = nonDhcpOctets subnet;

            # Delete all possible PTRs in the static ranges
            deletes = map (oct: "update delete ${toString oct}.${zone}. PTR") staticOctets;

            # Add defined static PTR records
            subnetHosts = builtins.attrValues network.hosts.${sname};
            adds = map (
              h: "update add ${h.hostPart}.${zone}. 86400 PTR ${h.name}.${sname}.${domain}."
            ) subnetHosts;
          in
          [
            "server 127.0.0.1"
            "zone ${zone}"
          ]
          ++ deletes
          ++ adds
          ++ [ "send\n" ]
        ) subnets
      );
    in
    builtins.concatStringsSep "\n" commands;
in
{
  inherit namedConf nsupdateScriptContent;
}
