{
  flake.nixosModules.homelab =
    {
      self,
      inputs,
      ...
    }:
    {
      imports = [
        inputs.impermanence.nixosModules.impermanence
        self.nixosModules.homelab-persistence
        self.nixosModules.homelab-auto-update
        self.nixosModules.homelab-telegram-notify
        self.nixosModules.homelab-firewall
        self.nixosModules.homelab-network
      ];
    };
}
