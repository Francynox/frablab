{ config, inputs, ... }:
let
  cfg = config.services.francynox.adguardhome;
  adguardHomeConfigEtcPath = "adguardhome/AdGuardHome.yaml";
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops.secrets = {
    adguardhome-config = {
      sopsFile = "${inputs.frablab-config}/adguardhome/AdGuardHome.yaml";
      path = "/etc/${adguardHomeConfigEtcPath}";
      key = "";
      mode = "0600";
      owner = cfg.user;
      inherit (cfg) group;
      restartUnits = [ "adguardhome.service" ];
    };
  };

  services = {
    francynox = {
      adguardhome = {
        enable = true;
        configFile = "/etc/${adguardHomeConfigEtcPath}";
      };

      mutable-configs = {
        "${adguardHomeConfigEtcPath}" = {
          source = config.sops.secrets.adguardhome-config.path;
          mode = "0600";
          inherit (cfg) user;
          inherit (cfg) group;
          stopAutoUpgrade = false;
          pathToCheck = "${cfg.dataDir}/AdGuardHome.yaml";
        };
      };
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
