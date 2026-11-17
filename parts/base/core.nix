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
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      services = lib.mkIf (!config.boot.isContainer) {
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
