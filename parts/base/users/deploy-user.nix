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

        name = lib.mkOption {
          type = lib.types.str;
          default = "deploy";
          description = "The deploy username";
        };

        sshAuthorizedKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJcEAwMkXM8xXimM49TTDdlSkOv04XJRtqa0JNBe0T5C"
          ];
          description = "SSH authorized keys for the deploy user";
        };

        autologin = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable autologin for the user";
        };
      };

      config = {
        services.francynox.deploy-user = {
          inherit (cfg) enable;
          inherit (cfg) name;
          inherit (cfg) sshAuthorizedKeys;
          inherit (cfg) autologin;
        };
      };
    };
}
