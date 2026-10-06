{ config, frablabConfig, ... }:
let
  cfg = config.services.francynox.sparkyfitness;
  sopsFile = frablabConfig.sparkyfitness.envFile;
in
{
  sops.secrets = {
    "sparkyfitness/db-password" = {
      inherit sopsFile;
      key = "db-password";
      restartUnits = [
        "sparkyfitness-db-init.service"
        "sparkyfitness.service"
      ];
    };
    "sparkyfitness/app-db-password" = {
      inherit sopsFile;
      key = "app-db-password";
      restartUnits = [ "sparkyfitness.service" ];
    };
    "sparkyfitness/api-encryption-key" = {
      inherit sopsFile;
      key = "api-encryption-key";
      restartUnits = [ "sparkyfitness.service" ];
    };
    "sparkyfitness/auth-secret" = {
      inherit sopsFile;
      key = "auth-secret";
      restartUnits = [ "sparkyfitness.service" ];
    };
  };

  sops.templates."sparkyfitness.env" = {
    content = ''
      SPARKY_FITNESS_DB_PASSWORD=${config.sops.placeholder."sparkyfitness/db-password"}
      SPARKY_FITNESS_APP_DB_PASSWORD=${config.sops.placeholder."sparkyfitness/app-db-password"}
      SPARKY_FITNESS_API_ENCRYPTION_KEY=${config.sops.placeholder."sparkyfitness/api-encryption-key"}
      BETTER_AUTH_SECRET=${config.sops.placeholder."sparkyfitness/auth-secret"}
    '';
    restartUnits = [
      "sparkyfitness-db-init.service"
      "sparkyfitness.service"
    ];
  };

  services.francynox.sparkyfitness = {
    enable = true;
    frontendUrl = "https://sparkyfitness.service.home.arpa";
    environmentFile = config.sops.templates."sparkyfitness.env".path;
  };

  frablab.homelab.persistence.directories = [
    cfg.stateDir
    config.services.postgresql.dataDir
    config.services.caddy.dataDir
  ];

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
  };
}
