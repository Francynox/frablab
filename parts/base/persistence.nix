{
  flake.nixosModules.base-persistence =
    { config, lib, ... }:
    let
      cfg = config.frablab.base;
    in
    {
      options.frablab.base.persistence.enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
        description = "Enable persistence configuration";
      };

      config = lib.mkIf cfg.persistence.enable {
        environment.persistence."/nix/persist" = {
          hideMounts = true;

          directories = [
            "/var/log"
            "/etc/nixos"
            "/var/lib/nixos"
            "/root"
          ];

          files = [
            "/etc/machine-id"
            "/etc/ssh/ssh_host_ed25519_key.pub"
            "/etc/ssh/ssh_host_ed25519_key"
            "/etc/ssh/ssh_host_rsa_key.pub"
            "/etc/ssh/ssh_host_rsa_key"
          ];
        };
      };
    };
}
