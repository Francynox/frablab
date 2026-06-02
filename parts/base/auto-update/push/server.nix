{
  flake.nixosModules.base-auto-update-push-server =
    {
      config,
      lib,
      self,
      constants,
      ...
    }:
    let
      cfg-base = config.frablab.base.auto-update.push;
      cfg = cfg-base.server;
    in
    {
      options.frablab.base.auto-update.push.server = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable the push auto-update webhook server";
        };

        domain = lib.mkOption {
          type = lib.types.str;
          default = config.frablab.network.hosts.mgmt.nixos-dev.fqdn;
          description = "Domain/FQDN of the webhook push server";
        };
      };

      config = lib.mkIf cfg.enable {
        sops.secrets = {
          deploy-token = {
            owner = config.services.webhook.user;
            inherit (config.services.webhook) group;
          };

          deploy-ssh-key = {
            sopsFile = self + "/secrets/deploy-ssh-key";
            format = "binary";
            owner = config.services.webhook.user;
            inherit (config.services.webhook) group;
          };

          github-pat-webhook = {
            key = "github-pat";
            owner = config.services.webhook.user;
            inherit (config.services.webhook) group;
          };
        };

        services.francynox.auto-update.push-server = {
          enable = true;
          flakePath = constants.flakeUrl;
          targetUser = config.frablab.base.users.deploy-user.name;
          tokenFile = config.sops.secrets.deploy-token.path;
          sshKeyFile = config.sops.secrets.deploy-ssh-key.path;
          githubPatFile = config.sops.secrets.github-pat-webhook.path;
          caddy = {
            enable = true;
            inherit (cfg) domain;
          };
        };
      };
    };
}
