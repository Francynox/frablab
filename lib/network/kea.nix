{ network }:
let
  inherit (network)
    subnets
    dhcpDomain
    ;

  isDhcpSubnet =
    subnet:
    subnet.dhcp != null || (builtins.any (hdata: hdata.mac != null) (builtins.attrValues subnet.hosts));

  activeDhcpSubnetNames = builtins.filter (sname: isDhcpSubnet subnets.${sname}) (
    builtins.attrNames subnets
  );

  mkSubnet4 =
    name: subnet:
    let
      v4Dns = subnet.dns.ipv4;
      hasDnsOverride = v4Dns != network.dns.ipv4;
      reservations = builtins.concatMap (
        hdata:
        if hdata.mac != null then
          [
            {
              hw-address = hdata.mac;
              ip-address = hdata.ipv4;
              hostname = hdata.name;
            }
          ]
        else
          [ ]
      ) (builtins.attrValues subnet.hosts);
    in
    {
      inherit (subnet) id;
      subnet = subnet.cidr;
      pools =
        if subnet.dhcp != null then
          [
            {
              pool = "${subnet.dhcp.start} - ${subnet.dhcp.end}";
            }
          ]
        else
          [ ];
      option-data = [
        {
          name = "routers";
          data = subnet.gateway.ipv4;
        }
        {
          name = "domain-name";
          data = "${name}.${dhcpDomain}";
        }
      ]
      ++ (
        if hasDnsOverride && v4Dns != [ ] then
          [
            {
              name = "domain-name-servers";
              data = builtins.concatStringsSep "," v4Dns;
            }
          ]
        else
          [ ]
      );
      ddns-qualifying-suffix = "${name}.${dhcpDomain}";
    }
    // (if reservations != [ ] then { inherit reservations; } else { })
    // (
      if subnet.dhcp != null && subnet.dhcp.validLifetime != null then
        { valid-lifetime = subnet.dhcp.validLifetime; }
      else
        { }
    );

  mkDhcp4Config =
    {
      interfaces ? [ "*" ],
      leaseFile ? "/var/lib/kea/dhcp4.leases",
      socketPath ? "/run/kea/kea-dhcp4.socket",
      dnsServers ? (network.dns.ipv4 or [ ]),
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

        option-data =
          if dnsServers != [ ] then
            [
              {
                name = "domain-name-servers";
                data = builtins.concatStringsSep "," dnsServers;
              }
            ]
          else
            [ ];

        subnet4 = map (sname: mkSubnet4 sname subnets.${sname}) activeDhcpSubnetNames;

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

      reverseZones = map (
        sname:
        let
          subnet = subnets.${sname};
        in
        {
          name = "${subnet.reverseZone}.";
          key-name = "dhcp-key";
          dns-servers = [
            {
              ip-address = dnsServerIp;
              port = dnsServerPort;
            }
          ];
        }
      ) activeDhcpSubnetNames;
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
