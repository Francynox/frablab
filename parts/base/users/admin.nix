{
  flake.nixosModules.base-users-admin =
    {
      config,
      lib,
      ...
    }:
    let
      cfg-persistence = config.frablab.base.persistence;
      cfg-base = config.frablab.base.users;
      cfg = cfg-base.admin;
    in
    {
      options.frablab.base.users.admin = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = cfg-base.enable;
          description = "Enable admin user";
        };

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

        extraGroups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Extra groups for the user";
        };

        persistenceFiles = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Files to persist for the user";
        };

        persistenceDirectories = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Directories to persist for the user";
        };
      };

      config = lib.mkIf cfg.enable {
        users.groups.${cfg.name} = { };
        users.users.${cfg.name} = {
          isNormalUser = true;
          description = cfg.name;
          group = lib.mkForce cfg.name;
          extraGroups = [
            "networkmanager"
            "wheel"
          ]
          ++ cfg.extraGroups;
          openssh.authorizedKeys.keys = cfg.sshAuthorizedKeys;
          inherit (cfg) initialHashedPassword;
        };

        environment.persistence = lib.mkIf cfg-persistence.enable {
          "/nix/persist" = {
            users.${cfg.name} = {
              directories = [
                {
                  directory = ".ssh";
                  mode = "0700";
                }
                ".config"
                ".local/share"
              ]
              ++ cfg.persistenceDirectories;
              files = [
                ".bash_history"
              ]
              ++ cfg.persistenceFiles;
            };
          };
        };
      };
    };
}
