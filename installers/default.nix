{ inputs, self, ... }:
{
  flake.nixosModules.installer-base = ./base.nix;

  perSystem =
    {
      pkgs,
      commonArgs,
      ...
    }:
    {
      packages = {
        iso = inputs.nixos-generators.nixosGenerate {
          inherit pkgs;
          format = "iso";
          specialArgs = commonArgs;
          modules = [
            self.nixosModules.installer-base
            ./iso
            inputs.disko.nixosModules.disko
          ];
        };

        proxmox-lxc = inputs.nixos-generators.nixosGenerate {
          inherit pkgs;
          format = "proxmox-lxc";
          specialArgs = commonArgs;
          modules = [
            self.nixosModules.installer-base
            ./lxc
          ];
        };
      };
    };
}
