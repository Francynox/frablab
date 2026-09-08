{
  flake.nixosModules.homelab =
    {
      self,
      lib,
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

      options.frablab.homelab = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable frablab homelab cluster configuration";
        };
      };
    };
}
