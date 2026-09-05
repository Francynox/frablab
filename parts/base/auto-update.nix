{
  flake.nixosModules.base-auto-update =
    {
      config,
      lib,
      options,
      constants,
      self,
      ...
    }:
    let
      cfg-base = config.frablab.base;
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
      config = lib.mkIf cfg-base.enable {
        services.francynox.auto-update = {
          enable = lib.mkDefault true;

          pull = {
            inherit (constants) flakeUrl;
            secretsUrl = constants.remoteSecretsUrl;
            inherit (constants) sopsKeyPath;
          };

          push = {
            webhook = {
              url = lib.mkDefault "http://${config.frablab.network.hosts.mgmt.nixos-dev.fqdn}:${toString options.services.francynox.auto-update.push-server.port.default}/hooks/deploy";
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
