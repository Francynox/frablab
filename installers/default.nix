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
        proxmox-image =
          let
            sys = inputs.nixpkgs.lib.nixosSystem {
              inherit pkgs;
              specialArgs = commonArgs;
              modules = [
                "${inputs.nixpkgs}/nixos/modules/virtualisation/proxmox-image.nix"
                self.nixosModules.installer-base
                ./vma
              ];
            };
          in
          sys.config.system.build.VMA;

        proxmox-lxc =
          let
            sys = inputs.nixpkgs.lib.nixosSystem {
              inherit pkgs;
              specialArgs = commonArgs;
              modules = [
                "${inputs.nixpkgs}/nixos/modules/virtualisation/proxmox-lxc.nix"
                self.nixosModules.installer-base
                ./lxc
              ];
            };
          in
          sys.config.system.build.tarball;
      };
    };
}
