{
  flake.nixosModules.base-users-deploy-user =
    {
      config,
      lib,
      ...
    }:
    let
      cfg-base = config.frablab.base.users;
      cfg = cfg-base.deploy-user;
    in
    {
      options.frablab.base.users.deploy-user = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = cfg-base.enable;
          description = "Enable deploy user";
        };
      };

      config = lib.mkIf cfg.enable {
        services.francynox.deploy-user = {
          enable = lib.mkDefault true;
          sshAuthorizedKeys = lib.mkDefault [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJcEAwMkXM8xXimM49TTDdlSkOv04XJRtqa0JNBe0T5C"
          ];
        };
      };
    };
}
