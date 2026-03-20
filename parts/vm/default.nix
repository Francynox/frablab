{
  flake.nixosModules.vm =
    { self, ... }:
    {
      imports = [
        self.nixosModules.vm-efi
        self.nixosModules.vm-disko
        self.nixosModules.vm-swap
      ];
    };
}
