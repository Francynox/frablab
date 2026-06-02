{
  flake.nixosModules.base-core =
    {
      config,
      lib,
      inputs,
      constants,
      self,
      ...
    }:
    let
      cfg-base = config.frablab.base;
      cfg = cfg-base.core;
    in
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      options.frablab.base.core = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = cfg-base.enable;
          description = "Enable frablab base configuration";
        };
      };

      config = lib.mkIf cfg.enable {
        services = {
          power-profiles-daemon = {
            enable = true;
          };
          upower.enable = true;
          fstrim.enable = true;
          qemuGuest.enable = true;
        };

        time.timeZone = "Europe/Rome";

        sops = {
          defaultSopsFile = self + "/secrets/secrets.yaml";
          age.sshKeyPaths = [
            constants.sopsKeyPath
          ];
          secrets = {
            telegram-token = {
              owner = config.services.francynox.telegram-notify.user;
              group = config.services.francynox.telegram-notify.group;
            };
            telegram-chat-id = {
              owner = config.services.francynox.telegram-notify.user;
              group = config.services.francynox.telegram-notify.group;
            };
          };
        };

        services.francynox.telegram-notify = {
          enable = true;
          botTokenFile = config.sops.secrets.telegram-token.path;
          chatIdFile = config.sops.secrets.telegram-chat-id.path;
        };

        # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
        system.stateVersion = "26.05";
      };
    };
}
