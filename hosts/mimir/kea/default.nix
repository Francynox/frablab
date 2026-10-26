{
  pkgs,
  config,
  inputs,
  ...
}:
let
  cfg = config.services.francynox.kea;

  keaLib = inputs.self.lib.network.mkKea {
    network = config.frablab.network;
  };

  dhcp4StaticConfig = (pkgs.formats.json { }).generate "kea-dhcp4.json" (
    keaLib.mkDhcp4Config {
      dnsServers = config.frablab.homelab.network.dns;
    }
  );

  dhcpDdnsConfigJson = (pkgs.formats.json { }).generate "kea-dhcp-ddns.json" (
    keaLib.mkDhcpDdnsConfig {
      inherit dhcpDdnsKeyPath;
    }
  );

  dhcp4ConfigEtcPath = "kea/kea-dhcp4.conf";
  dhcpDdnsConfigEtcPath = "kea/kea-dhcp-ddns.conf";
  dhcpDdnsKeyPath = "/etc/kea/dhcp-ddns.key";
in
{
  sops.secrets.kea-dhcp-key = {
    sopsFile = ./kea-dhcp-ddns.key;
    path = dhcpDdnsKeyPath;
    format = "binary";
    mode = "0600";
    owner = cfg.user;
    inherit (cfg) group;
    restartUnits = [ "kea-dhcp-ddns.service" ];
  };

  services.francynox = {
    kea = {
      dhcp4 = {
        enable = true;
        configFile = "/etc/${dhcp4ConfigEtcPath}";
        extraRestartTriggers = [ dhcp4StaticConfig ];
      };

      dhcp-ddns = {
        enable = true;
        configFile = "/etc/${dhcpDdnsConfigEtcPath}";
        extraRestartTriggers = [ dhcpDdnsConfigJson ];
      };
    };

    mutable-configs = {
      "${dhcp4ConfigEtcPath}" = {
        source = dhcp4StaticConfig;
        format = "json";
      };
      "${dhcpDdnsConfigEtcPath}" = {
        source = dhcpDdnsConfigJson;
        format = "json";
      };
    };
  };

  frablab.homelab.persistence.directories = [
    "${cfg.dataDir}"
  ];

  networking.firewall.allowedUDPPorts = [ 67 ];
}
