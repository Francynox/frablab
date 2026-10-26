{
  flake.nixosModules.homelab-auto-update =
    {
      config,
      lib,
      constants,
      self,
      ...
    }:
    let
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
      };
    in
    {
      options.frablab.homelab.auto-update = {
        pushWebhookUrl = lib.mkOption {
          type = lib.types.str;
          default = "http://${config.frablab.network.hosts.mgmt.nixos-dev.fqdn}:${toString pushServerCfg.port}/hooks/deploy";
          description = "Webhook URL the push client notifies. Defaults to this cluster's push-server (nixos-dev).";
        };
      };

      config = {
        services.francynox.auto-update = {
          enable = lib.mkDefault true;

          pull = {
            inherit (constants) flakeUrl;
          };

          push = {
            webhook = {
              url = lib.mkDefault config.frablab.homelab.auto-update.pushWebhookUrl;
              tokenFile = config.sops.secrets.deploy-token.path;
            };
          };

          push-server = {
            flakePath = constants.flakeUrl;
            targetUser = config.services.francynox.deploy-user.name;
            tokenFile = config.sops.secrets.deploy-token.path;
            sshKeyFile = config.sops.secrets.deploy-ssh-key.path;
          };
        };

        sops.secrets = lib.mkMerge [
          (lib.mkIf (auCfg.enable && auCfg.mode == "push") pushClientSecrets)
          (lib.mkIf pushServerCfg.enable pushServerSecrets)
        ];
      };
    };
}
