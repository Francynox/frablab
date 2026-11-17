{
  flake.nixosModules.homelab-persistence =
    { config, lib, ... }:
    let
      cfg = config.frablab.homelab.persistence;

      persistenceEntryType = lib.types.listOf (
        lib.types.either lib.types.str (lib.types.attrsOf lib.types.anything)
      );

      userPersistenceSubmodule = lib.types.submodule {
        options = {
          directories = lib.mkOption {
            type = persistenceEntryType;
            default = [ ];
            description = "Directories to persist for the user";
          };

          files = lib.mkOption {
            type = persistenceEntryType;
            default = [ ];
            description = "Files to persist for the user";
          };
        };
      };
    in
    {
      options.frablab.homelab.persistence = {
        path = lib.mkOption {
          type = lib.types.str;
          default = "/nix/persist";
          description = "Root directory for persistent storage";
        };

        directories = lib.mkOption {
          type = persistenceEntryType;
          default = [ ];
          description = "Directories to persist";
        };

        files = lib.mkOption {
          type = persistenceEntryType;
          default = [ ];
          description = "Files to persist";
        };

        users = lib.mkOption {
          type = lib.types.attrsOf userPersistenceSubmodule;
          default = { };
          description = "Per-user directories and files to persist";
        };
      };

      config = {
        frablab.homelab.persistence.users.admin = {
          directories = [
            {
              directory = ".ssh";
              mode = "0700";
            }
            ".config"
            ".local/share"
          ];
          files = [
            ".bash_history"
          ];
        };

        environment.persistence.${cfg.path} = {
          hideMounts = true;

          directories = [
            "/var/log"
            "/etc/nixos"
            "/var/lib/nixos"
            "/root"
          ]
          ++ cfg.directories;

          files = [
            "/etc/machine-id"
            "/etc/ssh/ssh_host_ed25519_key.pub"
            "/etc/ssh/ssh_host_ed25519_key"
            "/etc/ssh/ssh_host_rsa_key.pub"
            "/etc/ssh/ssh_host_rsa_key"
          ]
          ++ cfg.files;

          inherit (cfg) users;
        };
      };
    };
}
