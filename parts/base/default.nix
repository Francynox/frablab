{
  flake.nixosModules.base =
    {
      self,
      lib,
      inputs,
      francynoxModulesList,
      ...
    }:
    {
      imports = [
        inputs.impermanence.nixosModules.impermanence
        self.nixosModules.base-core
        self.nixosModules.base-packages
        self.nixosModules.base-persistence
        self.nixosModules.base-networking
        self.nixosModules.base-ssh
        self.nixosModules.base-users
        self.nixosModules.base-nix-settings
        self.nixosModules.base-auto-update
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
