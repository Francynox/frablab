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

        auto-reboot = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable auto-reboot";
        };
      };

      config = lib.mkIf cfg.enable {
        services.francynox.auto-update.pull = {
          inherit (cfg) auto-reboot;
          inherit (constants) flakeUrl;
          secretsUrl = constants.remoteSecretsUrl;
          inherit (constants) sopsKeyPath;
        };
      };
    };
}
