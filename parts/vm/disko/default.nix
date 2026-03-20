{
  flake.nixosModules.vm-disko =
    { self, ... }:
    {
      imports = [
        self.nixosModules.vm-disko-main
      ];
    };
}
