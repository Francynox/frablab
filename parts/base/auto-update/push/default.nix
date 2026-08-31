{
  flake.nixosModules.base-auto-update-push =
    {
      config,
      lib,
      options,
      ...
    }:
    let
      cfg-base = config.frablab.base.auto-update;
      cfg = cfg-base.push;
    in
    {
      options.frablab.base.auto-update.push = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable push-based auto-update (triggered via webhook)";
        };

        webhook = {
          url = lib.mkOption {
            type = lib.types.str;
            default = "http://${config.frablab.base.auto-update.push.server.domain}:${toString options.services.francynox.auto-update.push-server.port.default}/hooks/deploy";
            description = "Webhook URL on builder (nixos-dev) to trigger push";
          };

          insecure = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Disable SSL verification for curl";
          };

          tokenFile = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = config.sops.secrets.deploy-token.path;
            description = "Path to file containing authorization token for webhook";
          };
        };

        autoReboot = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Automatically reboot target hosts if kernel/initrd/systemd changes.";
        };
      };

      config = lib.mkIf cfg.enable {
        sops.secrets.deploy-token = { };

        services.francynox.auto-update.push = {
          inherit (cfg) webhook autoReboot;
        };
      };
    };
}
