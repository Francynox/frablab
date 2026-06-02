{
  flake.nixosModules.lxc =
    { self, ... }:
    {
      imports = [
        self.nixosModules.lxc-configuration
      ];
    };
}
