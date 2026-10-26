{
  config,
  ...
}:
let
  cfg = config.services.francynox.sparkyfitness;
in
{
  sops.secrets = {
    "sparkyfitness/db-password" = {
      sopsFile = ./sparkyfitness.yaml;
      key = "db-password";
      restartUnits = [
        "sparkyfitness-db-init.service"
        "sparkyfitness.service"
      ];
    };
    "sparkyfitness/app-db-password" = {
      sopsFile = ./sparkyfitness.yaml;
      key = "app-db-password";
      restartUnits = [ "sparkyfitness.service" ];
    };
    "sparkyfitness/api-encryption-key" = {
      sopsFile = ./sparkyfitness.yaml;
      key = "api-encryption-key";
      restartUnits = [ "sparkyfitness.service" ];
    };
    "sparkyfitness/auth-secret" = {
      sopsFile = ./sparkyfitness.yaml;
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
    frontendUrl = "https://${config.networking.hostName}.${config.frablab.homelab.network.subnet}.${config.frablab.network.domain}";
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
