{ inputs, ... }:
{
  flake.nixosModules.base =
    {
      self,
      lib,
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
      ++ lib.attrValues inputs.nur-francynox.nixosModules;
    };
}
