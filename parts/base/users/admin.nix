{
  flake.nixosModules.base-users-admin =
    {
      config,
      lib,
      self,
      constants,
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

        passwordlessSudo = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Allow the admin user to run sudo without a password.";
        };

        extraGroups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Extra groups for admin user";
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

        exportDeploySshKey = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Export the deployment SSH key to the admin's .ssh directory";
        };
      };

      config = lib.mkIf cfg.enable {
        sops.secrets.admin-deploy-ssh-key = lib.mkIf cfg.exportDeploySshKey {
          sopsFile = self + "/secrets/deploy-ssh-key";
          format = "binary";
          path = "/home/admin/.ssh/deploy-ssh-key";
          owner = "admin";
          group = "admin";
          mode = "0600";
        };

        users.groups.admin = { };
        users.users.admin = {
          isNormalUser = true;
          description = "admin";
          group = lib.mkForce "admin";
          extraGroups = [
            "networkmanager"
            "wheel"
          ]
          ++ cfg.extraGroups;
          openssh.authorizedKeys.keys = constants.adminSshAuthorizedKeys;
          initialHashedPassword = lib.mkDefault constants.adminInitialHashedPassword;
        };

        security.sudo.extraRules = lib.mkIf cfg.passwordlessSudo [
          {
            users = [ "admin" ];
            commands = [
              {
                command = "ALL";
                options = [ "NOPASSWD" ];
              }
            ];
          }
        ];

        environment.persistence = lib.mkIf cfg-persistence.enable {
          "${cfg-persistence.path}" = {
            users.admin = {
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
