{
  flake.nixosModules.base-auto-update-pull =
    {
      config,
      lib,
      constants,
      ...
    }:
    let
      cfg-base = config.frablab.base.auto-update;
      cfg = cfg-base.pull;
    in
    {
      options.frablab.base.auto-update.pull = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable pull-based auto-update";
        };

        autoReboot = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable auto-reboot";
        };

        autoRollback = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Automatically rollback target host if deploy or healthcheck fails";
        };
      };

      config = lib.mkIf cfg.enable {
        services.francynox.auto-update.pull = {
          inherit (cfg) autoReboot autoRollback;
          inherit (constants) flakeUrl;
          secretsUrl = constants.remoteSecretsUrl;
          inherit (constants) sopsKeyPath;
        };
      };
    };
}
