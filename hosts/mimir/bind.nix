{
  pkgs,
  lib,
  config,
  frablabConfig,
  ...
}:
let
  cfg = config.services.francynox.bind;

  bindConfigEtcPath = "bind/named.conf";
  staticZonesPrefix = "bind/zones_static";
  dhcpKeyFile = "/etc/bind/dhcp-ddns.key";

  writeZone = name: content: pkgs.writeText name content;

  dnsZones = {
    staticZoneFiles = builtins.mapAttrs writeZone frablabConfig.dnsZones.staticZoneFiles;
    dynamicZoneFiles = builtins.mapAttrs writeZone frablabConfig.dnsZones.dynamicZoneFiles;
  };

  bind = {
    namedConf = pkgs.writeText "named.conf" (
      frablabConfig.bind.namedConf {
        inherit (cfg) dataDir;
        dhcpKeyFile = "${dhcpKeyFile}";
      }
    );
    nsupdateScript = pkgs.writeText "nsupdate-static-reverse.txt" frablabConfig.bind.nsupdateScriptContent;
    inherit (frablabConfig.bind) rndcKey dhcpKey;
  };
in
{
  sops.secrets = {
    bind-rndc-key = {
      sopsFile = bind.rndcKey;
      path = cfg.rndcKeyFile;
      format = "json";
      key = "data";
      mode = "0600";
      owner = cfg.user;
      inherit (cfg) group;
      restartUnits = [ "named.service" ];
    };
    bind-dhcp-key = {
      sopsFile = bind.dhcpKey;
      path = dhcpKeyFile;
      format = "json";
      key = "data";
      mode = "0600";
      owner = cfg.user;
      inherit (cfg) group;
      restartUnits = [ "named.service" ];
    };
  };

  services = {
    francynox = {
      bind = {
        enable = true;
        configFile = "/etc/${bindConfigEtcPath}";
        staticZoneFiles = builtins.mapAttrs (
          name: _: "/etc/${staticZonesPrefix}/${name}"
        ) dnsZones.staticZoneFiles;
        inherit (dnsZones) dynamicZoneFiles;
        extraRestartTriggers = [
          bind.namedConf
        ]
        ++ (lib.attrValues dnsZones.staticZoneFiles);
      };

      mutable-configs = {
        "${bindConfigEtcPath}" = {
          source = bind.namedConf;
        };
      }
      // (lib.mapAttrs' (
        name: source:
        lib.nameValuePair "${staticZonesPrefix}/${name}" {
          inherit source;
          pathToCheck = "${cfg.dataDir}/${name}";
        }
      ) dnsZones.staticZoneFiles);
    };
  };

  systemd.services.named-static-reverse-dns = {
    description = "Update static PTR records in dynamic reverse zones";
    after = [ "named.service" ];
    requires = [ "named.service" ];
    partOf = [ "named.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "update-static-reverse" ''
        retries=30
        until ${cfg.package}/bin/rndc -k ${cfg.rndcKeyFile} status >/dev/null 2>&1; do
          if [ "$retries" -le 0 ]; then
            echo "Timeout waiting for BIND to be responsive." >&2
            exit 1
          fi
          sleep 1
          retries=$((retries - 1))
        done

        ${cfg.package}/bin/nsupdate -k ${dhcpKeyFile} ${bind.nsupdateScript}
      '';
      RemainAfterExit = true;
    };
  };

  frablab.base.persistence.additionalDirectories = [
    "${cfg.dataDir}"
  ];

  networking = {
    firewall = {
      allowedTCPPorts = [
        53
        443
      ];
      allowedUDPPorts = [
        53
      ];
    };
  };
}
