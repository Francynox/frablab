{ inputs, withSystem, ... }:
let
  hosts = inputs.self.lib.hosts;

  mkHost =
    name: type:
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
          inputs.self.nixosModules.homelab
          ./${name}
        ]
        ++ {
          lxc = [ inputs.self.nixosModules.lxc ];
          kvm = [ inputs.self.nixosModules.vm ];
        }
        .${type};
      }
    );
in
{
  flake.nixosConfigurations = inputs.nixpkgs.lib.mapAttrs (name: type: mkHost name type) hosts;
}
