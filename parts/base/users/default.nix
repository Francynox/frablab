{
  flake.nixosModules.base-users =
    {
      self,
      config,
      lib,
      ...
    }:
    let
      cfg = config.frablab.base.users;
    in
    {
      imports = [
        self.nixosModules.base-users-admin
        self.nixosModules.base-users-deploy-user
      ];

      options.frablab.base.users = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable users configuration";
        };
      };

      config = lib.mkIf cfg.enable {
        users.mutableUsers = false;
        security.sudo.wheelNeedsPassword = false;
      };
    };
}
