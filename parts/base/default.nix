{ self, inputs, ... }:
{
  flake.nixosModules.base =
    { francynoxModulesList, ... }:
    {
      imports = [
        inputs.impermanence.nixosModules.impermanence
        self.nixosModules.base-core
        self.nixosModules.base-packages
        self.nixosModules.base-persistence
        self.nixosModules.base-networking
        self.nixosModules.base-ssh
        self.nixosModules.base-users
        self.nixosModules.base-nix
        self.nixosModules.base-swap
        self.nixosModules.base-auto-update
      ]
      ++ francynoxModulesList;
    };
}
