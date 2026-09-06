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
          inputs.self.nixosModules.lxc
        ]
        ++ inputs.nixpkgs.lib.optionals (type == "kvm") [
          inputs.self.nixosModules.vm
        ];
      }
    );
in
{
  flake.nixosConfigurations = {
    nixos-dev = mkHost "nixos-dev" "kvm";
    bifrost = mkHost "bifrost" "lxc";
    mimir = mkHost "mimir" "lxc";
  };
}
