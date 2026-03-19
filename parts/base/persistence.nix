{
  flake.nixosModules.base-persistence =
    { config, lib, ... }:
    let
      cfg-base = config.frablab.base;
      cfg = cfg-base.persistence;
    in
    {
      options.frablab.base.persistence = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = cfg-base.enable;
          description = "Enable persistence configuration";
        };

        additionalDirectories = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Directories to persist";
        };

        additionalFiles = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Files to persist";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.persistence."/nix/persist" = {
          hideMounts = true;

          directories = [
            "/var/log"
            "/etc/nixos"
            "/var/lib/nixos"
            "/root"
          ]
          ++ cfg.additionalDirectories;

          files = [
            "/etc/machine-id"
            "/etc/ssh/ssh_host_ed25519_key.pub"
            "/etc/ssh/ssh_host_ed25519_key"
            "/etc/ssh/ssh_host_rsa_key.pub"
            "/etc/ssh/ssh_host_rsa_key"
          ]
          ++ cfg.additionalFiles;
        };
      };
    };
}
