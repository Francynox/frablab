{
  self,
  ...
}:
{
  imports = [
    self.nixosModules.vm
    ./build.nix
  ];
}
