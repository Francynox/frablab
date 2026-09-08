{
  flake.nixosModules.homelab-telegram-notify =
    {
      config,
      lib,
      ...
    }:
    let
      cfg-homelab = config.frablab.homelab;
      cfg = cfg-homelab.telegram-notify;
    in
    {
      options.frablab.homelab.telegram-notify = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = cfg-homelab.enable;
          description = "Enable Telegram notifications for host events";
        };
      };

      config = lib.mkIf cfg.enable {
        sops.secrets = {
          telegram-token = {
            owner = config.services.francynox.telegram-notify.user;
            group = config.services.francynox.telegram-notify.group;
          };
          telegram-chat-id = {
            owner = config.services.francynox.telegram-notify.user;
            group = config.services.francynox.telegram-notify.group;
          };
        };

        services.francynox.telegram-notify = {
          enable = true;
          botTokenFile = config.sops.secrets.telegram-token.path;
          chatIdFile = config.sops.secrets.telegram-chat-id.path;
        };
      };
    };
}
