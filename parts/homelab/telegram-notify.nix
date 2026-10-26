{
  flake.nixosModules.homelab-telegram-notify =
    { config, ... }:
    {
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
}
