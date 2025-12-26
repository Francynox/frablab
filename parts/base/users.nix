{
  flake.nixosModules.base-users =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.frablab.base;
    in
    {
      options.frablab.base.users.enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
        description = "Enable users configuration";
      };

      options.frablab = {
        user = {
          name = lib.mkOption {
            type = lib.types.str;
            default = "admin";
            description = "The main username";
          };
          initialHashedPassword = lib.mkOption {
            type = lib.types.str;
            default = "$6$hwDphFD.UY.MLmFp$2YKY68ZzLYzgRu7Opu4qGAKn9W6k4GLpv2kTHCUh2Nhl4guFsIKHQcnxQhEkkRorEjk3uPm3xy1zgEnwDRW07/";
            description = "Initial hashed password for the user";
          };
          sshAuthorizedKeys = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJyYmElWbBrcNn+JDXUvV0VZP9ITcnVtW/h2Y26g2TP7"
            ];
            description = "SSH authorized keys for the user";
          };
          autologin = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable autologin for the user";
          };
        };
      };

      config = lib.mkIf cfg.users.enable {
        users.mutableUsers = false;
        users.users.${config.frablab.user.name} = {
          isNormalUser = true;
          description = config.frablab.user.name;
          extraGroups = [
            "networkmanager"
            "wheel"
          ];
          openssh.authorizedKeys.keys = config.frablab.user.sshAuthorizedKeys;
          inherit (config.frablab.user) initialHashedPassword;
        };
        security.sudo.wheelNeedsPassword = false;
        services.getty.autologinUser = lib.mkIf config.frablab.user.autologin config.frablab.user.name;
      };
    };
}
