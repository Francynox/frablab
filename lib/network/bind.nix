{
  network,
  lib,
}:
let
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
        lib.mapAttrsToList (sname: subnet: ''
          // ${sname} (${subnet.cidr})
          ${mkDhcpZoneBlock subnet.reverseZone "${dataDir}/db.${sname}" "PTR"}
        '') subnets
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
      commands = lib.concatLists (
        lib.mapAttrsToList (
          sname: subnet:
          let
            zone = subnet.reverseZone;
            subnetHosts = builtins.attrValues network.hosts.${sname};
            adds = map (
              h:
              let
                lastOctet = lib.last (lib.splitString "." h.ipv4);
              in
              "update add ${lastOctet}.${zone}. 86400 PTR ${h.fqdn}."
            ) subnetHosts;

            # Usable octet range for the subnet
            baseOctet = lib.toIntBase10 (lib.last (lib.splitString "." subnet.network));
            hostBits = 32 - subnet.mask;
            numIps =
              let
                pow2 = [
                  1
                  2
                  4
                  8
                  16
                  32
                  64
                  128
                  256
                ];
              in
              if hostBits >= 0 && hostBits <= 8 then builtins.elemAt pow2 hostBits else 256;
            startUsable = baseOctet + 1;
            endUsable = baseOctet + numIps - 2;

            deletes =
              if subnet.dhcp != null then
                let
                  startOctet = lib.toIntBase10 (lib.last (lib.splitString "." subnet.dhcp.start));
                  endOctet = lib.toIntBase10 (lib.last (lib.splitString "." subnet.dhcp.end));
                  staticOctets = (lib.range startUsable (startOctet - 1)) ++ (lib.range (endOctet + 1) endUsable);
                in
                map (oct: "update delete ${toString oct}.${zone}. PTR") staticOctets
              else
                map (oct: "update delete ${toString oct}.${zone}. PTR") (lib.range startUsable endUsable);
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
