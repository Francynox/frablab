{ inputs, withSystem, ... }:
let
  mkHost =
    name: type:
    assert builtins.elem type [
      "kvm"
      "lxc"
    ];
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
        ++ inputs.nixpkgs.lib.optionals (type == "lxc") [
          "${inputs.nixpkgs}/nixos/modules/virtualisation/proxmox-lxc.nix"
          inputs.self.nixosModules.lxc
        ]
        ++ inputs.nixpkgs.lib.optionals (type == "kvm") [
          "${inputs.nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
          inputs.self.nixosModules.vm-efi
        ];
      }
    );
in
{
  flake.nixosConfigurations = {
    nixos-dev = mkHost "nixos-dev" "kvm";
    bind = mkHost "bind" "lxc";
    kea = mkHost "kea" "lxc";
    adguardhome = mkHost "adguardhome" "lxc";
  };
}
