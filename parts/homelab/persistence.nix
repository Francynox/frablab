{
  flake.nixosModules.homelab-persistence =
    { config, lib, ... }:
    let
      cfg-homelab = config.frablab.homelab;
      cfg = cfg-homelab.persistence;
      adminCfg = config.frablab.base.users.admin;
    in
    {
      options = {
        frablab.homelab.persistence = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = cfg-homelab.enable;
            description = "Enable homelab persistence configuration";
          };

          path = lib.mkOption {
            type = lib.types.str;
            default = "/nix/persist";
            description = "Root directory for persistent storage";
          };

          directories = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Directories to persist";
          };

          files = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Files to persist";
          };
        };

        frablab.base.users.admin.persistence = {
          directories = lib.mkOption {
            type = lib.types.listOf lib.types.anything;
            default = [ ];
            description = "Directories to persist for admin";
          };

          files = lib.mkOption {
            type = lib.types.listOf lib.types.anything;
            default = [ ];
            description = "Files to persist for admin";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        environment.persistence."${cfg.path}" = {
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

          users.admin = lib.mkIf adminCfg.enable {
            directories = [
              {
                directory = ".ssh";
                mode = "0700";
              }
              ".config"
              ".local/share"
            ]
            ++ adminCfg.persistence.directories;
            files = [
              ".bash_history"
            ]
            ++ adminCfg.persistence.files;
          };
        };
      };
    };
}
