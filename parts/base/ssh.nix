{
  flake.nixosModules.base-ssh =
    { config, lib, ... }:
    let
      cfg = config.frablab.base;
    in
    {
      options.frablab.base.ssh.enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
        description = "Enable SSH configuration";
      };

      config = lib.mkIf cfg.ssh.enable {
        services = {
          openssh = {
            enable = true;
            settings = {
              PermitRootLogin = "no";
              PasswordAuthentication = false;
            };
            openFirewall = true;
          };
        };
      };
    };
}
