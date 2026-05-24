{
  config,
  inputs,
  frablabConfig,
  ...
}:
let
  cfg = config.services.francynox.adguardhome;
  adguardHomeConfig = frablabConfig.adguardhome;
  adguardHomeConfigEtcPath = "adguardhome/AdGuardHome.yaml";
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops.secrets = {
    adguardhome-config = {
      sopsFile = adguardHomeConfig;
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
