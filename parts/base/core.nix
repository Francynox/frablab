{
  flake.nixosModules.base-core =
    {
      inputs,
      constants,
      self,
      ...
    }:
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

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
}
