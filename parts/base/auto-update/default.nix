{
  flake.nixosModules.base-auto-update =
    {
      self,
      config,
      lib,
      ...
    }:
    let
      cfg-base = config.frablab.base;
      cfg = cfg-base.auto-update;
    in
    {
      imports = [
        self.nixosModules.base-auto-update-pull
        self.nixosModules.base-auto-update-push
        self.nixosModules.base-auto-update-push-server
      ];

      options.frablab.base.auto-update = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = cfg-base.enable;
          description = "Enable auto-update overall";
        };

        mode = lib.mkOption {
          type = lib.types.enum [
            "pull"
            "push"
          ];
          default = "pull";
          description = ''
            Auto-update mode.

            - pull: Pulls updates from the flake repository on boot.
            - push: Triggers a push-based update via a webhook.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        frablab.base.auto-update.pull.enable = cfg.mode == "pull";
        frablab.base.auto-update.push.enable = cfg.mode == "push";

        services.francynox.auto-update = {
          inherit (cfg) enable;
          inherit (cfg) mode;
        };
      };
    };
}
