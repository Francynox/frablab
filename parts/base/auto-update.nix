{
  flake.nixosModules.base-auto-update =
    {
      config,
      lib,
      constants,
      self,
      ...
    }:
    let
      cfg-base = config.frablab.base;
      cfg = cfg-base.auto-update;
      auCfg = config.services.francynox.auto-update;
      pushServerCfg = auCfg.push-server;
      webhook = config.services.webhook;

      # --- Push Client Secrets ---
      pushClientSecrets = {
        deploy-token = { };
      };

      # --- Push Server Secrets (owned by webhook daemon) ---
      pushServerSecrets = {
        deploy-token = {
          owner = webhook.user;
          inherit (webhook) group;
        };

        deploy-ssh-key = {
          sopsFile = self + "/secrets/deploy-ssh-key";
          format = "binary";
          owner = webhook.user;
          inherit (webhook) group;
        };

        github-pat-webhook = {
          key = "github-pat";
          owner = webhook.user;
          inherit (webhook) group;
        };
      };
    in
    {
      options.frablab.base.auto-update = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = cfg-base.enable;
          description = "Enable frablab auto-update configuration";
        };
      };

      config = lib.mkIf cfg.enable {
        services.francynox.auto-update = {
          enable = lib.mkDefault true;

          pull = {
            inherit (constants) flakeUrl;
            secretsUrl = constants.remoteSecretsUrl;
            inherit (constants) sopsKeyPath;
          };

          push = {
            webhook = {
              tokenFile = config.sops.secrets.deploy-token.path;
            };
          };

          push-server = {
            flakePath = constants.flakeUrl;
            targetUser = config.services.francynox.deploy-user.name;
            tokenFile = config.sops.secrets.deploy-token.path;
            sshKeyFile = config.sops.secrets.deploy-ssh-key.path;
            githubPatFile = config.sops.secrets.github-pat-webhook.path;
          };
        };

        sops.secrets = lib.mkMerge [
          (lib.mkIf (auCfg.enable && auCfg.mode == "push") pushClientSecrets)
          (lib.mkIf pushServerCfg.enable pushServerSecrets)
        ];
      };
    };
}
