{ inputs, withSystem, ... }:
let
  mkHost =
    name: isLxc:
    withSystem "x86_64-linux" (
      {
        pkgs,
        system,
        commonArgs,
        ...
      }:
      inputs.nixpkgs.lib.nixosSystem {
        inherit system pkgs;

        specialArgs = commonArgs;

        modules = [
          inputs.self.nixosModules.base
          ./${name}
        ]
        ++ inputs.nixpkgs.lib.optionals isLxc [
          "${inputs.nixpkgs}/nixos/modules/virtualisation/proxmox-lxc.nix"
        ]
        ++ inputs.nixpkgs.lib.optionals (!isLxc) [
          "${inputs.nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
        ];
      }
    );
in
{
  flake.nixosConfigurations = {
    nixos-dev = mkHost "nixos-dev" false;
    bind = mkHost "bind" true;
    kea = mkHost "kea" true;
  };
}
