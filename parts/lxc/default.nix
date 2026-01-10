{ self, ... }:
{
  flake.nixosModules.lxc = {
    imports = [
      self.nixosModules.lxc-configuration
      self.nixosModules.lxc-init-script
    ];
  };
}
