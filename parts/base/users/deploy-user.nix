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
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJyYmElWbBrcNn+JDXUvV0VZP9ITcnVtW/h2Y26g2TP7"
          ];
          description = "SSH authorized keys for the deploy user";
        };

        autologin = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable autologin for the user";
        };
      };

      config = lib.mkIf cfg.enable {
        users.groups.${cfg.name} = { };
        users.users.${cfg.name} = lib.mkIf cfg.enable {
          isNormalUser = true;
          description = "Deployment User";
          group = lib.mkForce cfg.name;
          extraGroups = [ "wheel" ];
          openssh.authorizedKeys.keys = cfg.sshAuthorizedKeys;
        };

        services.getty.autologinUser = lib.mkIf cfg.autologin cfg.name;
      };
    };
}
