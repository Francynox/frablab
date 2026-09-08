{
  flake.nixosModules.base-core =
    {
      config,
      lib,
      inputs,
      constants,
      self,
      ...
    }:
    let
      cfg-base = config.frablab.base;
    in
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      config = lib.mkIf cfg-base.enable {
        services = {
          power-profiles-daemon = {
            enable = true;
          };
          upower.enable = true;
          fstrim.enable = true;
        };

        time.timeZone = "Europe/Rome";

        sops = {
          defaultSopsFile = self + "/secrets/secrets.yaml";
          age.sshKeyPaths = [
            constants.sopsKeyPath
          ];
        };

        # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
        system.stateVersion = "26.05";
      };
    };
}
