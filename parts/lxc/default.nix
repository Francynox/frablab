{
  flake.nixosModules.lxc =
    { self, ... }:
    {
      imports = [
        self.nixosModules.lxc-configuration
        self.nixosModules.lxc-init-script
      ];
    };
}
