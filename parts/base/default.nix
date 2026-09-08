{
  flake.nixosModules.base =
    {
      self,
      lib,
      francynoxModulesList,
      ...
    }:
    {
      imports = [
        self.nixosModules.base-core
        self.nixosModules.base-packages
        self.nixosModules.base-ssh
        self.nixosModules.base-users
        self.nixosModules.base-nix-settings
        self.nixosModules.base-networking
      ]
      ++ francynoxModulesList;

      options.frablab.base = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable frablab base configuration";
        };
      };
    };
}
